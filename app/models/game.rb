class Game < ActiveRecord::Base
  attr_accessor :creator_plays_as_black # for checkbox access
  has_many :pieces
  belongs_to :white_user, class_name: 'User', foreign_key: :white_user_id
  belongs_to :black_user, class_name: 'User', foreign_key: :black_user_id
  validates :game_name, presence: { :message => "Game name is required!" }
  validates :white_user_id,
            presence: true, unless: :black_user_id?, on: :create
  validates :black_user_id,
            presence: true, unless: :white_user_id?, on: :create
  validate :user_id_exists, on: :create
  validate :white_user_id_exists, if: :white_user_id?, on: :update
  validate :black_user_id_exists, if: :black_user_id?, on: :update
  validate :users_must_be_different, on: :update
  validate :user_turn_must_be_valid, on: :update
  after_create :populate_board!

  # This is part of STI ~AMP:
  delegate :pawns, :queens, :kings, :knights, :rooks, :bishops, to: :pieces

  def populate_board!
    # Creates all 32 chess pieces with their initial X/Y coordinates.

    # Board is numbered as per standard. X = column, Y = row
    # Bottom (white) rows are 0 and 1, top (black) rows are 6 and 7
    # Make sure to keep this in mind when working the logic, it's set up
    # as the upper right quadrant of a graph (instead of thinking [row, column]
    # coordinates as you normally might for a matrix)
    populate_white_pieces
    populate_black_pieces
    white_user_id.nil? ? set_pieces_black_user_id : set_pieces_white_user_id
  end

  def set_pieces_black_user_id
    pieces.where(color: false).each do |curr_piece|
      curr_piece.update_attributes(user_id: black_user_id)
    end
  end

  def set_pieces_white_user_id
    pieces.where(color: true).each do |curr_piece|
      curr_piece.update_attributes(user_id: white_user_id)
    end
  end

  def set_turn_id (player_id)
    self.user_turn = player_id
    self.save!
  end

  def finish_turn(player)
    if player == black_user
      set_turn_id(white_user_id)
    else
      set_turn_id(black_user_id)
    end
  end

  def current_player
    if self.user_turn == black_user_id
      return self.black_user
    else
      return self.white_user
    end
  end

  def player_missing?
    white_user.nil? || black_user.nil?
  end

  def determine_check(king)
    # if king is in check, returns list of pieces that threaten it - will evaluate to true if present
    # instead of just returning true/false, I have this method return the list of enemy pieces putting the
    # king in check to try to DRY up the code
    threatening_pieces = []
    opponents_pieces = self.pieces.where(color: !king.color, captured: false)
    opponents_pieces.each do |piece|
      if piece.valid_move?(king.x_position, king.y_position)
        self.update_attributes(check_status: 1)
        threatening_pieces << piece
      end
    end
    if threatening_pieces.any?
      return threatening_pieces
    end
    self.update_attributes(check_status: 0)
    return false
  end

  def check?
    check_status == 1 ? true : false
  end

  def puts_king_in_check?(king, x_dest, y_dest)
    # have to temporarily move the king around to see if it ends up in check
    king_orig_x_pos = king.x_position
    king_orig_y_pos = king.y_position
    if king.valid_move?(x_dest, y_dest)
      # see if enemy piece is there, temporarily remove it for these checks
      destination_piece = self.pieces.where(color: !king.color, x_position: x_dest, y_position: y_dest).first
      if destination_piece
        destination_piece.update_attributes(x_position: nil, y_position: nil, captured: true)
      end
      king.update_attributes(x_position: x_dest, y_position: y_dest)
    else
      return nil #nil for bad moves
    end
    opponents_pieces = self.pieces.where(color: !king.color, captured: false)
    opponents_pieces.each do |piece|
      if piece.valid_move?(king.x_position, king.y_position)
        king.update_attributes(x_position: king_orig_x_pos, y_position: king_orig_y_pos)
        if destination_piece
          destination_piece.update_attributes(x_position: x_dest, y_position: y_dest, captured: false)
        end
        return true 
      end
    end
    king.update_attributes(x_position: king_orig_x_pos, y_position: king_orig_y_pos)
    if destination_piece
      destination_piece.update_attributes(x_position: x_dest, y_position: y_dest, captured: false)
    end
    return false
  end

  def checkmate?(king)
    # going to assume for now that a valid king object is passed in...
    threatening_pieces = determine_check(king) # piece(s) putting king into check
    return false unless threatening_pieces # king isn't in check! 
    # try moving king in every direction to escape check, if any valid move then checkmate is false
    result = puts_king_in_check?(king, king.x_position, king.y_position+1) # up
    if !result && !result.nil? # if false and not nil then it is a valid move out of check
      return false # can escape check
    end
    result = puts_king_in_check?(king, king.x_position+1, king.y_position+1) # up-right
    if !result && !result.nil?
      return false
    end
    result = puts_king_in_check?(king, king.x_position+1, king.y_position) # right
    if !result && !result.nil?
      return false
    end
    result = puts_king_in_check?(king, king.x_position+1, king.y_position-1) # down-right
    if !result && !result.nil?
      return false
    end
    result = puts_king_in_check?(king, king.x_position, king.y_position-1) # down
    if !result && !result.nil?
      return false
    end
    result = puts_king_in_check?(king, king.x_position-1, king.y_position-1) # down-left
    if !result && !result.nil?
      return false
    end
    result = puts_king_in_check?(king, king.x_position-1, king.y_position) # left
    if !result && !result.nil?
      return false
    end
    result = puts_king_in_check?(king, king.x_position-1, king.y_position+1) # up-left
    if !result && !result.nil?
      return false
    end
    result = puts_king_in_check?(king, king.x_position, king.y_position+1) # up
    if !result && !result.nil?
      return false
    end

    threatening_pieces.each do |enemy_piece|
      range_to_check = range_between_pieces(king, enemy_piece) #get x and y coord of squares between king and enemy
      friendly_pieces = self.pieces.where(color: king.color, captured: false).where.not(piece_type: "King") # returns empty array if no results
      friendly_pieces.each do |friendly_piece|
        # can any friendly piece capture threatening piece? then break for this threatening piece
        if friendly_piece.valid_move?(enemy_piece.x_position, enemy_piece.y_position)
          enemy_piece_orig_x_pos = enemy_piece.x_position
          enemy_piece_orig_y_pos = enemy_piece.y_position
          friendly_piece_orig_x_pos = friendly_piece.x_position
          friendly_piece_orig_y_pos = friendly_piece.y_position
          # temporarily move pieces to determine if king still in check
          enemy_piece.update_attributes(x_position: nil, y_position: nil, captured: true)
          friendly_piece.update_attributes(x_position: enemy_piece_orig_x_pos, y_position: enemy_piece_orig_y_pos)
          king_still_checked = determine_check(king)
          # set pieces back to original state
          enemy_piece.update_attributes(x_position: enemy_piece_orig_x_pos, y_position: enemy_piece_orig_y_pos, captured: false)
          friendly_piece.update_attributes(x_position: friendly_piece_orig_x_pos, y_position: friendly_piece_orig_y_pos)
          if !king_still_checked # capturing enemy piece takes king out of check
            return false
          end
        end
        unless enemy_piece.piece_type == "Knight" # can't block knight, and it couldn't be captured by this friendly piece
          # can this friendly piece block check?
          # determine movement path from enemy to king - then see if any friendly piece has valid move within that line
          if !range_to_check.nil? # either an enemy knight or a non-threat (shouldn't happen) - not vert, horiz, or diagonal
            range_to_check.each do |square| # loop through every square between enemy and king (not including their positions)
              if friendly_piece.valid_move?(square[0], square[1]) #pull out x and y values to see if we can block
                friendly_piece_orig_x_pos = friendly_piece.x_position
                friendly_piece_orig_y_pos = friendly_piece.y_position
                # temporarily update friendly piece to blocking position to see if it blocks check
                friendly_piece.update_attributes(x_position: square[0], y_position: square[1])
                king_still_checked = determine_check(king)
                # set friendly piece back
                friendly_piece.update_attributes(x_position: friendly_piece_orig_x_pos, y_position: friendly_piece_orig_y_pos)
                if !king_still_checked # blocking this enemy piece will take friendly king out of check
                  return false # not checkmate
                end
              end # if piece can move into blocking path
            end # range loop
          end # nil check
        end # check if enemy is knight to skip block-checking
      end # friendly pieces
    end # enemy pieces
    # if nothing can get king out of check, then it is checkmate :(
    return true
  end

  def range_between_pieces(piece_one, piece_two)
    # will return an array of all x + y coords between 2 squares occupied by the 2 passed in pieces
    # only horizontal, vertical, and diagonal ranges are allowed (will return empty array if invalid)
    # does not include the start or end square
    position_array = []
    return position_array if piece_one == piece_two # same position
    if piece_one.x_position == piece_two.x_position #vertical
      if piece_one.y_position > piece_two.y_position
        vert_range = (piece_two.y_position..piece_one.y_position).to_a
      else
        vert_range = (piece_one.y_position..piece_two.y_position).to_a
      end
      vert_range = vert_range[1, vert_range.length - 2] # chop off first and last element (for enemy and king) - nil if squares adjacent
      unless vert_range.nil? # if squares aren't next to each other
        vert_range.each do |y_coord|
          position_array << [piece_one.x_position, y_coord]
        end
      end
      return position_array
    end
    if piece_one.y_position == piece_two.y_position #horizontal
      if piece_one.x_position > piece_two.x_position
        horiz_range = (piece_two.x_position..piece_one.x_position).to_a
      else
        horiz_range = (piece_one.x_position..piece_two.x_position).to_a
      end
      horiz_range = horiz_range[1, horiz_range.length - 2] # chop off first and last element (for enemy and king) - nil if squares adjacent
      unless horiz_range.nil?
        horiz_range.each do |x_coord|
          position_array << [x_coord, piece_one.y_position]
        end
      end
      return position_array
    end
    if (piece_one.x_position - piece_two.x_position).abs == (piece_one.y_position - piece_two.y_position).abs #diagonal
      state_x = piece_one.x_position
      state_y = piece_one.y_position
      delta_x = piece_two.x_position - piece_one.x_position
      delta_y = piece_two.y_position - piece_one.y_position
      if delta_x == delta_y && delta_x > 0
        # NE move: positive X, positive Y diagonal
        steps = delta_x - 1
        steps.times do
          state_x += 1
          state_y += 1
          position_array << [state_x, state_y]
        end
        return position_array
      elsif delta_x == delta_y && delta_x < 0
        # SW move: negative X negative Y diagonal
        steps = delta_x.abs - 1
        steps.times do
          state_x -= 1
          state_y -= 1
          position_array << [state_x, state_y]
        end
        return position_array
      elsif delta_x > 0 && delta_y < 0 && delta_x == delta_y.abs
        # SE move: positive X, negative Y diagonal
        steps = delta_x - 1
        steps.times do
          state_x += 1
          state_y -= 1
          position_array << [state_x, state_y]
        end
        return position_array
      elsif delta_x < 0 && delta_y > 0 && delta_x.abs == delta_y
        # NW move: negative X, positive Y diagonal
        steps = delta_y - 1
        steps.times do
          state_x -= 1
          state_y += 1
          position_array << [state_x, state_y]
        end
        return position_array
      end
    end
  end

  private

  def populate_white_pieces
    # Create white pieces (color == true for white):
    # White Pawns
    populate_pawns(true)
    # White Knights
    populate_knights(true)
    # White Bishops
    populate_bishops(true)
    # White Rooks
    populate_rooks(true)
    # White Queen
    Queen.create(game_id: id, x_position: 3, y_position: 0,
                 color: true)
    # White King
    King.create(game_id: id, x_position: 4, y_position: 0,
                color: true)
  end

  def populate_black_pieces
    # Create black pieces (color == false for black):
    # Black Pawns
    populate_pawns(false)
    # Black Knights
    populate_knights(false)
    # Black Bishops
    populate_bishops(false)
    # Black Rooks
    populate_rooks(false)
    # Black Queen
    Queen.create(game_id: id, x_position: 3, y_position: 7,
                 color: false)
    # Black King
    King.create(game_id: id, x_position: 4, y_position: 7,
                color: false)
  end

  def populate_pawns(is_white)
    is_white ? pawn_y_position = 1 : pawn_y_position = 6
    (0..7).each do |a|
      Pawn.create(game_id: id, x_position: a, y_position: pawn_y_position,
                  color: is_white)
    end
  end

  def populate_knights(is_white)
    is_white ? knight_y_position = 0 : knight_y_position = 7
    Knight.create(game_id: id, x_position: 1, y_position: knight_y_position,
                  color: is_white)
    Knight.create(game_id: id, x_position: 6, y_position: knight_y_position,
                  color: is_white)
  end

  def populate_bishops(is_white)
    is_white ? bishop_y_position = 0 : bishop_y_position = 7
    Bishop.create(game_id: id, x_position: 2, y_position: bishop_y_position,
                  color: is_white)
    Bishop.create(game_id: id, x_position: 5, y_position: bishop_y_position,
                  color: is_white)
  end

  def populate_rooks(is_white)
    is_white ? rook_y_position = 0 : rook_y_position = 7
    Rook.create(game_id: id, x_position: 0, y_position: rook_y_position,
                color: is_white)
    Rook.create(game_id: id, x_position: 7, y_position: rook_y_position,
                color: is_white)
  end

  def user_id_exists
    if white_user_id? && User.find_by_id(white_user_id).nil?
      errors.add(:white_user_id, 'must be an existing user!')
    elsif black_user_id? && User.find_by_id(black_user_id).nil?
      errors.add(:black_user_id, 'must be an existing user!')
    end
  end

  def white_user_id_exists
    return unless User.find_by_id(white_user_id).nil?
    errors.add(:white_user_id, 'must be an existing user!')
  end

  def black_user_id_exists
    return unless User.find_by_id(black_user_id).nil?
    errors.add(:black_user_id, 'must be an existing user!')
  end

  def users_must_be_different
    return unless black_user_id == white_user_id
    errors.add(:base, 'White and Black users cannot be the same!')
  end

  def user_turn_must_be_valid
    return unless (user_turn != white_user_id) && (user_turn != black_user_id)
    errors.add(:user_turn, 'Current turn is neither white or black user!')
  end
end
