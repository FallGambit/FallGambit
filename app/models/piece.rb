class Piece < ActiveRecord::Base
  belongs_to :user
  belongs_to :game
  validates :x_position, :presence => true,
                         :numericality => { greater_than_or_equal_to: 0,
                                            less_than_or_equal_to: 7 },
                         allow_nil: true
  validates :y_position, :presence => true,
                         :numericality => { greater_than_or_equal_to: 0,
                                            less_than_or_equal_to: 7 },
                         allow_nil: true
  after_initialize :set_image

  # Lines 16-22 all part of STI: to break it disable line 6 or give
  # self.inheritance_column a fake field name ~AMP
  self.inheritance_column = :piece_type
  scope :pawns, -> { where(piece_type: "Pawn") }
  scope :queens, -> { where(piece_type: "Queen") }
  scope :kings, -> { where(piece_type: "King") }
  scope :rooks, -> { where(piece_type: "Rook") }
  scope :knights, -> { where(piece_type: "Knight") }
  scope :bishops, -> { where(piece_type: "Bishop") }

  def self.piece_types
    %w(Pawn Queen King Rook Knight Bishop)
  end

  def x_y_coords
    x_y_coordinates = []
    x_y_coordinates << x_position
    x_y_coordinates << y_position
    x_y_coordinates
  end

  def set_image
    color ? color_string = "white" : color_string = "black"
    self.image_name ||= "#{color_string}-#{piece_type.downcase}.png"
  end

  def move_to!(x, y)
    @target = game.pieces.where(:x_position => x, :y_position => y).take
    fail "Invalid move: [error to be defined]" unless valid_move?(x, y)
    if @target.nil?
      update_attributes(:x_position => x, :y_position => y)
    else
      fail "Invalid move: same color piece" if color == @target.color
      capture(x, y)
    end
  end

  def capture(x, y)
    update_attributes(:x_position => x, :y_position => y)
    @target.update_attributes(:captured => true,
                              :x_position => nil,
                              :y_position => nil)
  end

  def find_piece(x, y)
    game.pieces.where("x_position = ? AND y_position = ?", x, y)
  end

  def square_occupied?(x, y)
    find_piece(x, y).any?
  end

  def range_occupied?(x1, x2, y1, y2)
    # Use Restriction: x1 < x2, y1 < y2
    game.pieces
      .where("x_position BETWEEN ? AND ? AND y_position BETWEEN ? AND ?",
             x1, x2, y1, y2).any?
  end

  def is_obstructed?(dest_x, dest_y)
    state_x = x_position
    state_y = y_position
    delta_x = dest_x - state_x
    delta_y = dest_y - state_y

    if delta_x != 0 && delta_y != 0 && delta_x.abs != delta_y.abs
      # this handles invalid input or invalid moves.
      # should this include tests for values over 7 and non-numeric input?
      fail "Invalid input or invalid move."
    elsif delta_y == 0 && delta_x > 0 && delta_x.abs > 1
      # horizontal move where start is < destination and distance > 1
      return self.range_occupied?((state_x + 1), (dest_x - 1), state_y, state_y)
    elsif delta_y == 0 && delta_x < 0 && delta_x.abs > 1
      # horizontal move where start is > destination and distance > 1
      return self.range_occupied?((dest_x + 1), (state_x - 1), state_y, state_y)
    elsif delta_y == 0 && delta_x.abs <= 1
      # horizontal move to next square or delta 0
      return false
    elsif delta_x == 0 && delta_y > 0 && delta_y.abs > 1
      # vertical move where start is < destination and distance > 1
      return self.range_occupied?(state_x, state_x, (state_y + 1), (dest_y - 1))
    elsif delta_x == 0 && delta_y < 0 && delta_y.abs > 1
      # vertical move where start is > destination and distance > 1
      return self.range_occupied?(state_x, state_x, (dest_y + 1), (state_y - 1))
    elsif delta_x == 0 && delta_y.abs <= 1
      # vertical move to next square or delta 0
      return false
    elsif delta_x == delta_y && delta_x > 0
      # NE move: positive X, positive Y diagonal
      steps = delta_x - 1
      steps.times do
        state_x += 1
        state_y += 1
        return true if self.square_occupied?((state_x), (state_y))
      end
      return false
    elsif delta_x == delta_y && delta_x < 0
      # SW move: negative X negative Y diagonal
      steps = delta_x.abs - 1
      steps.times do
        state_x -= 1
        state_y -= 1
        return true if self.square_occupied?((state_x), (state_y))
      end
      return false
    elsif delta_x > 0 && delta_y < 0 && delta_x == delta_y.abs
      # SE move: positive X, negative Y diagonal
      steps = delta_x - 1
      steps.times do
        state_x += 1
        state_y -= 1
        return true if self.square_occupied?((state_x), (state_y))
      end
      return false
    elsif delta_x < 0 && delta_y > 0 && delta_x.abs == delta_y
      # NW move: negative X, positive Y diagonal
      steps = delta_y - 1
      steps.times do
        state_x -= 1
        state_y += 1
        return true if self.square_occupied?((state_x), (state_y))
      end
      return false
    end
  end
end
