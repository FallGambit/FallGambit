class PiecesController < ApplicationController
  before_action :authenticate_user!

  def show
    @piece = Piece.find(params[:id])
    @current_game = current_game
  end

  def update
    @piece = Piece.find(params[:id])
    @piece.update_attributes(x_position: params[:x], y_position: params[:y])
    redirect_to game_path(@piece.game)
  end


  private

  helper_method :current_game, :show_piece_td

  def current_game
    @piece = Piece.find(params[:id])
    @current_game ||= @piece.game
  end

  def board_display_piece_query(row, column)
    current_game.pieces.find do |f|
      f["x_position"] == column && f["y_position"] == row
    end
  end

  def show_piece_td(row, column)
    @current_game = current_game
    find_piece = board_display_piece_query(row, column)
    board_square = "<td class='x-position-'#{column}' "
    board_square += "piece-id-data='#{piece_id(find_piece)}' "
    board_square += "piece-type-data='#{piece_type(find_piece)}''>"
      url = piece_path(Piece.find(params[:id]))
      url += "?x=#{column}&y=#{row}"
    if find_piece.nil?
      board_square += ActionController::Base.helpers.link_to '', url, method: :put
    else
      image = ActionController::Base.helpers.image_tag find_piece
                      .image_name, size: '40x45',
                                   class: 'img-responsive center-block'
      board_square += ActionController::Base.helpers.link_to image, url, method: :put    
    end
    board_square + "</td>"
  end

  def piece_id(piece)
    piece.present? ? piece.id : nil
  end

  def piece_type(piece)
    piece.present? ? piece.piece_type : nil
  end
end
