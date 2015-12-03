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

  # Lines 7-17 all part of STI: to break it disable line 6 or give it
  # fake field name ~AMP
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

  def is_obstructed?(x, y)
    dest_x = x
    dest_y = y
    state_x = x_position
    state_y = y_position
    delta_x = dest_x - state_x
    delta_y = dest_y - state_y

    if delta_y == 0 && delta_x > 0 && delta_x.abs > 1
      # horizontal move where start is < destination and distance > 1
      return self.game.pieces.where("y_position = ? AND x_position BETWEEN ? AND ?", state_y, (state_x + 1), (dest_x - 1)).any?
    elsif delta_y == 0 && delta_x < 0 && delta_x.abs > 1
      # horizontal move where start is > destination and distance > 1
      return self.game.pieces.where("y_position = ? AND x_position BETWEEN ? AND ?", state_y, (dest_x + 1), (state_x - 1)).any?
    elsif delta_y == 0 && delta_x.abs <= 1
      # horizontal move to next square or delta 0
      return false
    elsif delta_x == 0 && delta_y > 0 && delta_y.abs > 1
      # vertical move where start is < destination and distance > 1
      return self.game.pieces.where("x_position = ? AND y_position BETWEEN ? AND ?", state_x, (state_y + 1), (dest_y - 1)).any?
    elsif delta_x == 0 && delta_y < 0 && delta_y.abs > 1
      # vertical move where start is > destination and distance > 1
      return self.game.pieces.where("x_position = ? AND y_position BETWEEN ? AND ?", state_x, (dest_y + 1), (state_y - 1)).any?
    elsif delta_x == 0 && delta_y.abs <= 1
      # vertical move to next square or delta 0
      return false
    elsif delta_x == delta_y && delta_x > 0
      # SE move, positive X, positive Y diagonal
      steps = delta_x - 1
      while steps != 0
        if self.game.pieces.where("x_position = ? AND y_position = ?", (state_x + steps), (state_y + steps)).any?
          return true
        end
        steps -= 1
      end
      return false
    elsif delta_x == delta_y && delta_x < 0
      # NW move, negative X negative Y diagonal
      steps = delta_x.abs - 1
      while steps != 0
        if self.game.pieces.where("x_position = ? AND y_position = ?", (state_x - steps), (state_y - steps)).any?
          return true
        end
        steps -= 1
      end
      return false
    elsif delta_x > 0 && delta_y < 0 && delta_x == delta_y.abs
      # NE move, positive X, negative Y diagonal
      steps = delta_x - 1
      while steps != 0
        if self.game.pieces.where("x_position = ? AND y_position = ?", (state_x + steps), (state_y - steps)).any?
          return true
        end
        steps -= 1
      end
      return false
    elsif delta_x < 0 && delta_y > 0 && delta_x.abs == delta_y
      # SW move, negative X, positive Y diagonal
      steps = delta_y - 1
      while steps != 0
        if self.game.pieces.where("x_position = ? AND y_position = ?", (state_x - steps), (state_y + steps)).any?
          return true
        end
        steps -= 1
      end
      return false
    elsif delta_x != 0 && delta_y != 0 && delta_x.abs != delta_y.abs
      # this handles invalid input or invalid moves.
      # raise "Invalid input or invalid move."
      return "Invalid input or invalid move."
    end
  end
end
