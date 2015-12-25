class Pawn < Piece
  def valid_move?(dest_x, dest_y)
    dest_piece = game.pieces
                 .where("x_position = ? AND y_position = ?", dest_x, dest_y)
                 .take
    return false if is_obstructed?(dest_x, dest_y)
    return false if dest_x < 0 || dest_x > 7 || dest_y < 0 || dest_y > 7
    return false if dest_piece && dest_piece.color == color
    (one_forward(dest_x, dest_y) && dest_piece.nil?) ||
    (two_forward(dest_x, dest_y) && dest_piece.nil?) ||
    (one_diagonal(dest_x, dest_y) && !dest_piece.nil?)
  end

  def white_moving
    color
  end

  def one_forward(dest_x, dest_y)
    if white_moving
      dest_x == x_position && dest_y == y_position + 1
    else
      dest_x == x_position && dest_y == y_position - 1
    end
  end

  def two_forward(dest_x, dest_y)
    if white_moving
      y_position == 1 && dest_x == x_position && dest_y == y_position + 2
    else
      y_position == 6 && dest_x == x_position && dest_y == y_position - 2
    end
  end

  def one_diagonal(dest_x, dest_y)
    if white_moving
      dest_y == y_position + 1 && (dest_x == x_position + 1 || dest_x == x_position - 1)
    else
      dest_y == y_position - 1 && (dest_x == x_position + 1 || dest_x == x_position - 1)
    end
  end
end
