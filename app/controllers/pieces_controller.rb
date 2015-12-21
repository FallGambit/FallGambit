class PiecesController < ApplicationController
  before_action :authenticate_user!
  before_action :must_be_users_turn, :must_be_users_piece
  after_action :flash_notice, only: :update

  def show
    if @piece.game.player_missing?
      flash[:alert] = "Cannot move until both players have joined!"
      redirect_to game_path(@piece.game)
    end
    @piece = Piece.find(params[:id])
    @current_game = current_game
  end

  def update
    if @piece.game.player_missing?
      flash[:alert] = "Cannot move until both players have joined!"
      redirect_to game_path(@piece.game) and return
    end
    @piece = Piece.find(params[:id])
    new_x = params[:x].to_i
    new_y = params[:y].to_i
    if @piece.move_to!(new_x, new_y)
      @piece.game.finish_turn(@piece.user)
    end
    redirect_to game_path(@piece.game)
  end

  private

  def flash_notice
    if @piece.flash_message.present?
      flash[:alert] = @piece.flash_message
    end
  end

  helper_method :current_game, :show_piece_td

  def flash_notice
    if @piece.flash_message.present?
      flash[:alert] = @piece.flash_message
    end
  end

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
      board_square += ActionController::Base.helpers.link_to '',
                                                             url, method: :put
    else
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

  def must_be_users_turn
    if current_user.id != current_game.user_turn
      flash[:alert] = "Not your turn!"
      redirect_to game_path(current_game)
    end
  end

  def must_be_users_piece
    if @piece.user.nil? || current_user.id != @piece.user.id
      flash[:alert] = "Not your piece!"
      redirect_to game_path(current_game)
    end
  end

end
