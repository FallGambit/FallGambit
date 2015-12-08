require 'rails_helper'

RSpec.describe Piece, type: :model do
  describe "instantiation" do
    let(:game) { create(:game) }

    it "sets the white queen image correctly" do
      expect(game.queens.where(color: true).first.image_name)
        .to eq('white-queen.png')
    end

    it "won't allow pieces to be created outside of board" do
      king = King.create(user_id: game.white_user_id, x_position: -1,
                         y_position: 4)
      queen = Queen.create(user_id: game.black_user_id, x_position: 4,
                           y_position: 9)
      pawn = Pawn.create(user_id: game.white_user_id, x_position: 9,
                         y_position: 9)
      knight = Knight.create(user_id: game.black_user_id, x_position: -1,
                             y_position: -1)
      expect(king).not_to be_valid
      expect(queen).not_to be_valid
      expect(pawn).not_to be_valid
      expect(knight).not_to be_valid
    end
  end

  describe "moving pieces" do
    let(:game) { create(:game) }

    it "won't allow pieces to be moved outside of board" do
      king = game.kings.first
      expect(king).to be_valid
      king.update_attributes(x_position: -1)
      expect(king).not_to be_valid
      king.update_attributes(x_position: 11)
      expect(king).not_to be_valid
      king.errors.clear
      king.update_attributes(y_position: -1)
      expect(king).not_to be_valid
      king.errors.clear
      king.update_attributes(y_position: 11)
      expect(king).not_to be_valid
      king.errors.clear
      king.update_attributes(x_position: -1, y_position: -1)
      expect(king).not_to be_valid
      king.errors.clear
      king.update_attributes(x_position: 11, y_position: 11)
      expect(king).not_to be_valid
      king.errors.clear
      king.update_attributes(x_position: -1, y_position: 11)
      expect(king).not_to be_valid
      king.errors.clear
    end
  end

  describe "#move_to!" do
    context "when the tile is empty" do
      it "moves to the coordinates" do
        board = create(:game)
        board.pieces.delete_all
        king = King.create(x_position: 1, y_position: 1, game_id: board.id)
        king.move_to!(2, 2)
        expect(king.x_position).to eq(2)
        expect(king.y_position).to eq(2)
      end
    end
    context "when the tile is not empty" do
      it "captures the opponent piece and moves to the new coordinates" do
        board = create(:game)
        board.pieces.delete_all
        white_king = King.create(x_position: 1, y_position: 1,
                                 game_id: board.id, color: true)
        black_knight = Knight.create(x_position: 2, y_position: 2,
                                     game_id: board.id, color: false)

        white_king.move_to!(2, 2)
        expect(white_king.x_position).to eq(2)
        expect(white_king.y_position).to eq(2)
        black_knight.reload
        expect(black_knight.captured).to be(true)
        expect(black_knight.x_position).to be_nil
        expect(black_knight.y_position).to be_nil
      end
    end
    context "tries to capture a piece with an invalid move" do
      it "king doesn't capture a piece two spaces away" do
        board = create(:game)
        board.pieces.delete_all
        white_king = King.create(x_position: 1, y_position: 1,
                                 game_id: board.id, color: true)

        expect { white_king.move_to!(3, 3) }
          .to raise_error(/Invalid/)
      end
    end
    context "when the pieces are of the same color" do
      it "doesn't capture a same color piece" do
        board = create(:game)
        board.pieces.delete_all
        white_king = King.create(x_position: 1, y_position: 1,
                                 game_id: board.id, color: true)
        white_knight = Knight.create(x_position: 2, y_position: 2,
                                     game_id: board.id, color: true)

        expect { white_king.move_to!(2, 2) }
          .to raise_error(/Invalid/)
      end
    end
  end

  describe 'is_obstructed?' do
    before :all do
      @game = FactoryGirl.create(:game)
      @game.pieces.delete_all
      @white_queen = Queen.create(
        x_position: 2,
        y_position: 0,
        color: true,
        game_id: @game.id
      )
      @white_knight = Knight.create(
        x_position: 1,
        y_position: 0,
        color: true,
        game_id: @game.id
      )
      @white_pawn = Pawn.create(
        x_position: 1,
        y_position: 1,
        color: true,
        game_id: @game.id
      )
      @white_bishop = Bishop.create(
        x_position: 2,
        y_position: 4,
        color: true,
        game_id: @game.id
      )
      @white_rook = Rook.create(
        x_position: 2,
        y_position: 7,
        color: true,
        game_id: @game.id
      )
      @black_pawn = Pawn.create(
        x_position: 6,
        y_position: 4,
        color: false,
        game_id: @game.id
      )
      @black_queen = Queen.create(
        x_position: 4,
        y_position: 6,
        color: false,
        game_id: @game.id
      )
      @black_rook = Rook.create(
        x_position: 6,
        y_position: 6,
        color: false,
        game_id: @game.id
      )
      @black_bishop = Bishop.create(
        x_position: 5,
        y_position: 4,
        color: false,
        game_id: @game.id
      )
    end

    it 'will raise an Error Message with invalid input' do
      expect { @white_queen.is_obstructed?(4, 3) }
        .to raise_error("Invalid input or invalid move.")
    end

    it 'will be false when horizontal axis path is clear' do
      expect(@white_queen.is_obstructed?(5, 0)).to eq false
    end

    it 'will be false when horiz axis path clear neg direction' do
      expect(@black_queen.is_obstructed?(1, 6)).to eq false
    end

    it 'will be false when moves to next square in horiz axis' do
      expect(@black_queen.is_obstructed?(5, 6)).to eq false
    end

    it 'will be false with move to next square horiz negative' do
      expect(@black_queen.is_obstructed?(3, 6)).to eq false
    end

    it 'will be true when there is a block in horizontal axis' do
      expect(@black_queen.is_obstructed?(7, 6)).to eq true
    end

    it 'will be true with block in horiz axis neg direction' do
      expect(@white_queen.is_obstructed?(0, 0)).to eq true
    end

    it 'will be true with block in vertical axis' do
      expect(@white_queen.is_obstructed?(2, 5)).to eq true
    end

    it 'will be true with block in vertical axis, neg direction' do
      expect(@white_rook.is_obstructed?(2, 3)).to eq true
    end

    it 'will be false when vertical axis path is clear' do
      expect(@white_queen.is_obstructed?(2, 3)).to eq false
    end

    it 'will be false when vertical axis path clear neg direction' do
      expect(@black_queen.is_obstructed?(4, 1)).to eq false
    end

    it 'will be false with move to next square vertical axis' do
      expect(@white_queen.is_obstructed?(2, 1)).to eq false
    end

    it 'will be false with move to next square vert axis negative' do
      expect(@black_queen.is_obstructed?(4, 5)).to eq false
    end

    it 'will be false when NE diag path is clear' do
      expect(@white_queen.is_obstructed?(4, 2)).to eq false
    end

    it 'will be false when NE diag path clear, piece at endpoint' do
      expect(@white_queen.is_obstructed?(6, 4)).to eq false
    end

    it 'will be true when NE diag path has block' do
      expect(@white_queen.is_obstructed?(7, 5)).to eq true
    end

    it 'will be false when SE diag path is clear' do
      expect(@white_bishop.is_obstructed?(5, 1)).to eq false
    end

    it 'will be false when SE diag path clear, piece at endpoint' do
      expect(@black_queen.is_obstructed?(6, 4)).to eq false
    end

    it 'will be true when SE diag path has block, neg direction' do
      expect(@black_queen.is_obstructed?(7, 3)).to eq true
    end

    it 'will be false when SW diag path is clear' do
      expect(@white_bishop.is_obstructed?(0, 2)).to eq false
    end

    it 'will be false when SW diag path clear, piece at endpoint' do
      expect(@black_queen.is_obstructed?(2, 4)).to eq false
    end

    it 'will be true when SW diag path blocked' do
      expect(@black_queen.is_obstructed?(1, 3)).to eq true
    end

    it 'will be false when NW diag path is clear' do
      expect(@white_bishop.is_obstructed?(0, 6)).to eq false
    end

    it 'will be false when NW diag path clear, piece at endpoint' do
      expect(@black_bishop.is_obstructed?(2, 7)).to eq false
    end

    it 'will be true when NW diag path blocked' do
      expect(@white_queen.is_obstructed?(0, 2)).to eq true
    end

    it 'will be false with clear path if destination contains piece' do
      # also tests single space movement graceful handling in diagonal
      expect(@white_queen.is_obstructed?(1, 1)).to eq false
    end

    after :all do
      @game.pieces.delete_all
      @game.delete
    end
  end
end
