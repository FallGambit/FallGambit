require 'rails_helper'

RSpec.describe King, type: :model do
  describe 'valid_move?' do
    before :all do
      @game = FactoryGirl.create(:game)
      @game.pieces.destroy_all
      @wking = King.create(x_position: 4, y_position: 3, game_id: @game.id, color: true)
      @wpawn = Pawn.create(x_position: 3, y_position: 2, game_id: @game.id, color: true)
      @bpawn = Pawn.create(x_position: 5, y_position: 2, game_id: @game.id, color: false)
    end

    it "should be true when moving 1 space up" do
      actual = @wking.valid_move?(4, 4)
      expect(actual).to be(true)
    end

    it "should be true when moving 1 space diagonal" do
      actual = @wking.valid_move?(5, 4)
      expect(actual).to be(true)
    end

    it "should be false when moving 2 spaces right" do
      actual = @wking.valid_move?(6, 3)
      expect(actual).to be(false)
    end

    it "should be false when moving 3 spaces diagonally" do
      actual = @wking.valid_move?(7, 6)
      expect(actual).to be(false)
    end

    it "should be false when moving 3 spaces back diagonally" do
      actual = @wking.valid_move?(1, 0)
      expect(actual).to be(false)
    end

    it "should be false when moving 3 spaces down" do
      actual = @wking.valid_move?(4, 0)
      expect(actual).to be(false)
    end

    it "should be false when moving onto tile with same colored piece" do
      actual = @wking.valid_move?(3, 2)
      expect(actual).to be(false)
    end

    it "should be true when moving onto tile with different colored piece" do
      actual = @wking.valid_move?(5, 2)
      expect(actual).to be(true)
    end

    it "should be false when moving off the board" do
      actual = @wking.valid_move?(-1, 2)
      expect(actual).to be(false)
    end
  end

  describe "castling" do
    before :each do
      @board = create(:game)
      @board.pieces.delete_all
      @black_king = King.create(x_position: 4, y_position: 7, color: false,
                                game_id: @board.id)
      @black_kingside_rook = Rook.create(x_position: 7, y_position: 7,
                                         color: false, game_id: @board.id)
      @black_queenside_rook = Rook.create(x_position: 0, y_position: 7,
                                          color: false, game_id: @board.id)
      @white_king = King.create(x_position: 4, y_position: 0, color: true,
                                game_id: @board.id)
      @white_kingside_rook = Rook.create(x_position: 7, y_position: 0,
                                         color: true, game_id: @board.id)
      @white_queenside_rook = Rook.create(x_position: 0, y_position: 0,
                                          color: true, game_id: @board.id)
      @board.reload
    end
    context "valid castle moves" do
      it "allows queenside castle" do
        expect(@black_king.can_castle?(@black_queenside_rook)).to be true
        expect(@white_king.can_castle?(@white_queenside_rook)).to be true
      end
      it "allows kingside castle" do
        expect(@black_king.can_castle?(@black_kingside_rook)).to be true
        expect(@white_king.can_castle?(@white_kingside_rook)).to be true
      end
      it "moves black queenside castle" do
        @black_king.castle!(@black_queenside_rook)
        expect(@black_king.x_y_coords).to eq [2, 7]
        expect(@black_queenside_rook.x_y_coords).to eq [3, 7]
      end
      it "moves white queenside castle" do
        @white_king.castle!(@white_queenside_rook)
        expect(@white_king.x_y_coords).to eq [2, 0]
        expect(@white_queenside_rook.x_y_coords).to eq [3, 0]
      end
      it "moves black kingside castle" do
        @black_king.castle!(@black_kingside_rook)
        expect(@black_king.x_y_coords).to eq [6, 7]
        expect(@black_kingside_rook.x_y_coords).to eq [5, 7]
      end
      it "moves white kingside castle" do
        @white_king.castle!(@white_kingside_rook)
        expect(@white_king.x_y_coords).to eq [6, 0]
        expect(@white_kingside_rook.x_y_coords).to eq [5, 0]
      end
    end
    context "invalid castle moves" do
      it "does not allow castle if the rook is not on the first row" do
        @white_kingside_rook.delete
        white_kingside_rook = Rook.create(x_position: 0, y_position: 1,
                                          color: true, game_id: @board.id)
        expect(@white_king.can_castle?(white_kingside_rook)).to be false
      end
      it "does not allow castle if the king is not on the first row" do
        @white_king.delete
        white_king = King.create(x_position: 4, y_position: 1,
                                 color: true, game_id: @board.id)
        expect(white_king.can_castle?(@white_kingside_rook)).to be false
      end
      it "does not allow castle if the rook has moved" do
        @black_queenside_rook.move_to!(0, 5)
        @black_queenside_rook.move_to!(0, 7)
        expect(@black_king.can_castle?(@black_queenside_rook)).to be false
      end
      it "does not allow castle if the king has moved" do
        @black_king.move_to!(5, 6)
        @black_king.move_to!(4, 7)
        expect(@black_king.can_castle?(@black_kingside_rook)).to be false
        expect(@black_king.can_castle?(@black_queenside_rook)).to be false
      end
      it "does not allow castle if there are pieces between king and rook" do
        white_kingside_bishop = Bishop.create(x_position: 5, y_position: 0)
        expect(@white_king.can_castle?(white_kingside_bishop)).to be false
      end
      it "does not allow castle if the other piece is not a rook" do
        @black_kingside_rook.delete
        black_kingside_knight = Knight.create(x_position: 7, y_position: 7,
                                              color: false, game_id: @board.id)
        expect(@black_king.can_castle?(black_kingside_knight)).to be false
      end
      it "does not allow castle if the other piece is not the same color" do
        @white_kingside_rook.update_attributes(color: false)
        expect(@white_king.can_castle?(@white_kingside_rook)).to be false
      end
      it "does not allow castle from a piece in another game" do
        game2 = create(:game)
        white_queenside_rook2 = game2.pieces.where(x_position: 0,
                                                   y_position: 0).take
        expect(@white_king.can_castle?(white_queenside_rook2)).to be false
      end
      context "start, moves through, or ends in check" do
        it "does not allow castle if the king currently is in check" do
          # set up situation where king is in check to start
          @black_kingside_rook.update_attributes(x_position: 4, y_position: 5)
          expect(@white_king.can_castle?(@white_kingside_rook)).to be false
          expect(@white_king.flash_message).to eq "Can't castle while in check!"
        end
        it "does not allow castle if the king moves through check" do
          # set up situation where the king moves through check while castling
          @black_kingside_rook.update_attributes(x_position: 5, y_position: 5)
          expect(@white_king.can_castle?(@white_kingside_rook)).to be false
          expect(@white_king.flash_message).to eq "Cannot move King into check while castling!"
        end
        it "does not allow castle if the king ends in check" do
          # set up situation where king ends in check after a castle
          @black_kingside_rook.update_attributes(x_position: 6, y_position: 5)
          expect(@white_king.can_castle?(@white_kingside_rook)).to be false
          expect(@white_king.flash_message).to eq "Cannot move King into check while castling!"
        end
      end
      it "does not move the pieces" do
        @black_queenside_rook.move_to!(0, 5)
        @black_queenside_rook.move_to!(0, 7)
        expect(@black_king.castle!(@black_queenside_rook)).to be false
        expect(@black_king.flash_message).to match(/Can't castle! Rook already moved!/)
      end
    end
  end
end
