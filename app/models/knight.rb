class Knight < Piece
  def is_obstructed?(_dest_x, _dest_y)
    false
  end

  def valid_move?(dest_x, dest_y)
    delta_x = (dest_x - x_position).abs
    delta_y = (dest_y - y_position).abs
    dest_piece = game.pieces.where("x_position = ? AND y_position = ?",
                                   dest_x, dest_y).take
    return false if dest_x < 0 || dest_x > 7 || dest_y < 0 || dest_y > 7
    return false if dest_piece && dest_piece.color == color
    return true if delta_x == 2 && delta_y == 1
    return true if delta_x == 1 && delta_y == 2
    false
  end
end
