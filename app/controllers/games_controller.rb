class GamesController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :update, :move]

  def new
    @game = Game.new
  end

  def create
    @game = Game.create(game_create_params)
    if @game.valid?
      redirect_to game_path(@game)
      begin
        # update game listing in real time
        PrivatePub.publish_to("/", "window.location.reload();")
      rescue Errno::ECONNREFUSED
        flash.now[:alert] = "Pushing to Faye Failed"
      end
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
    if @game.player_missing?
      update_player
      if @game.errors.empty?
        flash[:notice] = "Joined the game!"
        redirect_to game_path(@game)
        begin
          PrivatePub.publish_to("/games/#{@game.id}", "window.location.reload();")
        rescue Errno::ECONNREFUSED
          flash.now[:alert] = "Pushing to Faye Failed"
        end
        return
      end
    end
    handle_update_errors
  end

  def move
    respond_to do |format|
      format.json { redirect_to piece_path(params[:piece_id]) }
      format.html { redirect_to game_path(current_game) }
    end
  end

  def forfeit
    if current_user.id == current_game.white_user_id
      current_game.update_attributes(game_winner: current_game.black_user_id)
    elsif current_user.id == current_game.black_user_id
      current_game.update_attributes(game_winner: current_game.white_user_id)
    end
    redirect_to game_path(current_game)
    begin
      PrivatePub.publish_to("/games/#{current_game.id}", "window.location.reload();")
    rescue Errno::ECONNREFUSED
      flash.now[:alert] = "Pushing to Faye Failed"
    end
  end

  def request_draw
    current_game.update_attributes(draw_request: current_user.id)
    redirect_to game_path(current_game)
    begin
      PrivatePub.publish_to("/games/#{current_game.id}", "window.location.reload();")
    rescue Errno::ECONNREFUSED
      flash.now[:alert] = "Pushing to Faye Failed"
    end
  end

  def accept_draw
    current_game.update_attributes(draw: true)
    redirect_to game_path(current_game)
    begin
      PrivatePub.publish_to("/games/#{current_game.id}", "window.location.reload();")
    rescue Errno::ECONNREFUSED
      flash.now[:alert] = "Pushing to Faye Failed"
    end
  end

  def reject_draw
    current_game.update_attributes(draw_request: nil)
    redirect_to game_path(current_game)
    begin
      PrivatePub.publish_to("/games/#{current_game.id}", "window.location.reload();")
    rescue Errno::ECONNREFUSED
      flash.now[:alert] = "Pushing to Faye Failed"
    end
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
    board_square = "<td data-x-position='#{column}'"
    if find_piece.nil?
      board_square += ">"
    else
      board_square += " data-piece-id='#{piece_id(find_piece)}' "
      board_square += "data-piece-type='#{piece_type(find_piece)}'>"
      image = ActionController::Base.helpers.image_tag find_piece
              .image_name, size: '40x45',
                           class: 'img-responsive center-block'
      board_square += ActionController::Base.helpers
                      .link_to image, piece_path(find_piece)
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
      { white_user_id: current_user.id, user_turn: current_user.id }
    end
  end

  def game_create_params
    params.require(:game).permit(:game_name, :creator_plays_as_black,
                                 :white_user_id, :black_user_id, :user_turn)
      .merge(merge_player_color_choice_param)
  end

  def update_player
    if @game.white_user_id.nil?
      @game.update_attributes(white_user_id: current_user.id, user_turn: current_user.id)
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
