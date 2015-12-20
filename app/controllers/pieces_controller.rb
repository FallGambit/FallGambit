class PiecesController < ApplicationController
  before_action :authenticate_user!
  after_action :flash_notice, only: :update

  def show
    @piece = Piece.find(params[:id])
    @current_game = current_game
  end

  def update
    @piece = Piece.find(params[:id])
    new_x = params[:x].to_i
    new_y = params[:y].to_i
    @piece.move_to!(new_x, new_y)
    respond_to do |format|
      format.json { render :json => @piece.to_json }
      format.html { redirect_to game_path(@piece.game) }
    end
  end

  private

  def flash_notice
    if @piece.flash_message.present?
      flash[:alert] = @piece.flash_message
    end
  end

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
    board_square = "<td data-x-position='#{column}'"
    url = piece_path(Piece.find(params[:id]))
    url += "?x=#{column}&y=#{row}"
    if find_piece.nil?
      board_square += ">"
      board_square += ActionController::Base.helpers.link_to '',
                                                             url, method: :put
    else
      board_square += " data-piece-id='#{piece_id(find_piece)}' "
      board_square += "data-piece-type='#{piece_type(find_piece)}'>"
      image = ActionController::Base.helpers.image_tag find_piece
              .image_name, size: '40x45',
                           class: 'img-responsive center-block'
      board_square += ActionController::Base.helpers.link_to image,
                                                             url, method: :put
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
