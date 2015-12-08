class GamesController < ApplicationController
  before_action :authenticate_user!, only: [:create, :update]

  def new
    @game = Game.new
  end

  def create
    @game = Game.create(game_create_params)
    if @game.valid?
      redirect_to game_path(@game)
    else
      flash.now[:alert] = "Error creating game!"
      render :new, :status => :unprocessable_entity
    end
  end

  def show
    @game = Game.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render :text => "404 Error - Game Not Found", :status => :not_found
  end

  def update
    @game = Game.find(params[:id])
    if @game.white_user_id.nil? || @game.black_user_id.nil?
      update_player
      if @game.errors.empty?
        redirect_to game_path(@game)
        return
      end
    end
    handle_update_errors
  end

  private

  helper_method :current_game, :place_piece_td
  def current_game
    @current_game ||= Game.find(params[:id])
  end

  def board_display_piece_query(row, column)
    current_game.pieces.find do |f|
      f["x_position"] == column && f["y_position"] == row
    end
  end

  def place_piece_td(row, column)
    find_piece = board_display_piece_query(row, column)
    board_square = "<td class='x-position-'#{column}' "
    board_square += "piece-id-data='#{piece_id(find_piece)}' "
    board_square += "piece-type-data='#{piece_type(find_piece)}''>"
    unless find_piece.nil?
      image = ActionController::Base.helpers.image_tag find_piece
                                    .image_name, size: '40x45',
                                   class: 'img-responsive center-block'
      board_square += ActionController::Base.helpers.link_to image, piece_path(find_piece)
    end
    board_square + "</td>"
  end

  def piece_id(piece)
    piece.present? ? piece.id : nil
  end

  def piece_type(piece)
    piece.present? ? piece.piece_type : nil
  end

  def merge_player_color_choice_param
    if params[:game][:creator_plays_as_black] == '1'
      { black_user_id: current_user.id }
    else
      { white_user_id: current_user.id }
    end
  end

  def game_create_params
    params.require(:game).permit(:game_name, :creator_plays_as_black,
                                 :white_user_id, :black_user_id)
      .merge(merge_player_color_choice_param)
  end

  def update_player
    if @game.white_user_id.nil?
      @game.update_attributes(white_user_id: current_user.id)
      @game.set_pieces_white_user_id
    else
      @game.update_attributes(black_user_id: current_user.id)
      @game.set_pieces_black_user_id
    end
  end

  def handle_update_errors
    if @game.white_user_id? && @game.black_user_id?
      @game.errors.add(:base, "Game is full!")
    end
    flash[:alert] = @game.errors.full_messages.last
    redirect_to root_path
  end
end
