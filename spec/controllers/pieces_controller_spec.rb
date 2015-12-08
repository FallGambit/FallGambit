require 'rails_helper'

RSpec.describe PiecesController, type: :controller do
  before :each do
    @black_user = FactoryGirl.create(:user)
    @white_user = FactoryGirl.create(:user)
    sign_in @white_user
    sign_in @black_user
    @current_game = FactoryGirl.create(:game)
  end

  describe "movement" do
    it "will move 2 spaces up" do
      @piece = Piece.where(x_position: 6, y_position: 6).first
      put :update, id: @piece.id, x: 6, y: 4
      expected_y_position = 4
      @piece.reload
      expect(@piece.y_position).to be(expected_y_position)
    end

    it "will move 2 spaces left" do
      @piece = Piece.where(x_position: 6, y_position: 6).first
      put :update, id: @piece.id, x: 4, y: 6
      expected_x_position = 4
      @piece.reload
      expect(@piece.x_position).to be(expected_x_position)
    end
  end

  describe "#update" do
    it "will redirect to games page" do
      @piece = Piece.where(x_position: 6, y_position: 6).first
      put :update, id: @piece.id, x: 4, y: 6
      expect(response).to redirect_to :controller => :games, :action => :show,
                                      :id => @piece.game
    end
  end
end
