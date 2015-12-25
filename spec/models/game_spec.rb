require 'rails_helper'

RSpec.describe Game, type: :model do
  let(:build_game) { build(:game) }
  let(:game) { create(:game) }
  describe 'instantiation' do
    it 'instantiates a game' do
      expect(build_game.class.name).to eq("Game")
    end

    it 'has none to begin with' do
      expect(Game.count).to eq 0
    end

    context 'with valid params' do
      it 'populates the board with 32 pieces' do
        expect(game.pieces.count).to eq 32
      end

      it 'has count of one after adding one' do
        game
        expect(Game.count).to eq 1
      end

      # these tests assume no flipping of board perspective, white is on bottom
      context "while placing white pieces" do
        it "places the pawns in the correct squares" do
          # This creates an array of all x positions, and deletes each position
          # if it's found in the list of pawns (they all have the same y
          # coordinate). This checks the correct positions and intrinsically
          # provides a count of the pawns.
          x_list = *(0..7)
          game.pawns.where(color: true).each do |pawn|
            expect(x_list.delete_at(x_list.find_index(pawn.x_position)))
              .not_to be_nil
            expect(pawn.y_position).to eq 1
          end
          expect(x_list.empty?).to eq true
        end

        it "places the king in the correct square" do
          x_y_coords = game.kings.where(color: true).first.x_y_coords
          expect(x_y_coords).to eq([4, 0])
        end

        it "places the queen in the correct square" do
          x_y_coords = game.queens.where(color: true).first.x_y_coords
          expect(x_y_coords).to eq([3, 0])
        end

        it "places the knight in the correct square" do
          x_y_coord_list = []
          game.knights.where(color: true).each do |knight|
            x_y_coord_list << knight.x_y_coords
          end
          expect(x_y_coord_list).to contain_exactly([1, 0], [6, 0])
        end

        it "places the bishop in the correct square" do
          x_y_coord_list = []
          game.bishops.where(color: true).each do |bishop|
            x_y_coord_list << bishop.x_y_coords
          end
          expect(x_y_coord_list).to contain_exactly([2, 0], [5, 0])
        end

        it "places the rook in the correct square" do
          x_y_coord_list = []
          game.rooks.where(color: true).each do |rook|
            x_y_coord_list << rook.x_y_coords
          end
          expect(x_y_coord_list).to contain_exactly([0, 0], [7, 0])
        end
      end
      # these tests assume no flipping of board perspective, black is on top
      context "while placing black pieces" do
        it "places the pawns in the correct squares" do
          # This creates an array of all x positions, and deletes each position
          # if it's found in the list of pawns (they all have the same y-
          # coordinate). This checks the correct positions and intrinsically
          # provides a count of the pawns.
          x_list = *(0..7)
          game.pawns.where(color: false).each do |pawn|
            expect(x_list.delete_at(x_list.find_index(pawn.x_position)))
              .not_to be_nil
            expect(pawn.y_position).to eq 6
          end
          expect(x_list.empty?).to eq true
        end

        it "places the king in the correct square" do
          x_y_coords = game.kings.where(color: false).first.x_y_coords
          expect(x_y_coords).to eq([4, 7])
        end

        it "places the queen in the correct square" do
          x_y_coords = game.queens.where(color: false).first.x_y_coords
          expect(x_y_coords).to eq([3, 7])
        end

        it "places the knight in the correct square" do
          x_y_coord_list = []
          game.knights.where(color: false).each do |knight|
            x_y_coord_list << knight.x_y_coords
          end
          expect(x_y_coord_list).to contain_exactly([1, 7], [6, 7])
        end

        it "places the bishop in the correct square" do
          x_y_coord_list = []
          game.bishops.where(color: false).each do |bishop|
            x_y_coord_list << bishop.x_y_coords
          end
          expect(x_y_coord_list).to contain_exactly([2, 7], [5, 7])
        end

        it "places the rook in the correct square" do
          x_y_coord_list = []
          game.rooks.where(color: false).each do |rook|
            x_y_coord_list << rook.x_y_coords
          end
          expect(x_y_coord_list).to contain_exactly([0, 7], [7, 7])
        end
      end
    end

    context "with invalid params" do
      it "does not accept blank game name" do
        game = build(:game, game_name: "")
        game.valid?
        expect(game.errors[:game_name].size).to eq 1
      end

      it "does not accept no users on creation" do
        game.update_attributes(white_user_id: nil, black_user_id: nil)
        expect(game).to be_invalid
        expect(game.errors[:base].size).to eq 1
      end
    end
  end

  describe 'game update' do
    it 'won\'t let a user play against themself' do
      game.update_attributes(white_user_id: game.black_user_id)
      expect(game).to be_invalid
      expect(game.errors[:base].size).to eq 1
    end
  end

  describe "determine check" do
    context "white King" do
      it "should be held in check by black Knight and evades check" do
        white_king = game.kings.where(color: true).take
        black_knight = game.knights.where(color: false).first
        white_king.update_attributes(x_position: 4, y_position: 3)
        black_knight.update_attributes(x_position: 2, y_position: 4)
        game.determine_check(white_king)
        expect(game.check?).to eq(true)
        # King evades check
        white_king.update_attributes(x_position: 3, y_position: 3)
        game.determine_check(white_king)
        expect(game.check?).to eq(false)
      end
      it "should be held in check by black Pawn" do
        white_king = game.kings.where(color: true).take
        black_pawn = game.pawns.where(color: false).first
        white_king.update_attributes(x_position: 4, y_position: 3)
        black_pawn.update_attributes(x_position: 5, y_position: 4)
        game.determine_check(white_king)
        expect(game.check?).to eq(true)
      end
      it "should not be held in check by black Pawn" do
        white_king = game.kings.where(color: true).take
        black_pawn = game.pawns.where(color: false).first
        white_king.update_attributes(x_position: 3, y_position: 3)
        black_pawn.update_attributes(x_position: 5, y_position: 4)
        game.determine_check(white_king)
        expect(game.check?).to eq(false)
      end
      it "should be held in check by black Queen" do
        white_king = game.kings.where(color: true).take
        black_queen = game.queens.where(color: false).take
        white_king.update_attributes(x_position: 4, y_position: 3)
        black_queen.update_attributes(x_position: 6, y_position: 5)
        game.determine_check(white_king)
        expect(game.check?).to eq(true)
      end
      it "should be held in check by black Rook" do
        white_king = game.kings.where(color: true).take
        black_rook = game.rooks.where(color: false).first
        white_king.update_attributes(x_position: 4, y_position: 3)
        black_rook.update_attributes(x_position: 0, y_position: 3)
        game.determine_check(white_king)
        expect(game.check?).to eq(true)
      end
      it "should be held in check by black Bishop" do
        white_king = game.kings.where(color: true).take
        black_bishop = game.bishops.where(color: false).first
        white_king.update_attributes(x_position: 3, y_position: 2)
        black_bishop.update_attributes(x_position: 0, y_position: 5)
        game.determine_check(white_king)
        expect(game.check?).to eq(true)
      end
      it "should be held in check by black King" do
        white_king = game.kings.where(color: true).take
        black_king = game.kings.where(color: false).take
        white_king.update_attributes(x_position: 4, y_position: 3)
        black_king.update_attributes(x_position: 4, y_position: 4)
        game.determine_check(white_king)
        expect(game.check?).to eq(true)
      end
      it "should NOT be held in check by black King" do
        white_king = game.kings.where(color: true).take
        black_king = game.kings.where(color: false).take
        white_king.update_attributes(x_position: 4, y_position: 3)
        black_king.update_attributes(x_position: 2, y_position: 4)
        game.determine_check(white_king)
        expect(game.check?).to eq(false)
      end
    end

    context "black King" do
      it "should be held in check by white Knight" do
        black_king = game.kings.where(color: false).take
        white_knight = game.knights.where(color: true).first
        black_king.update_attributes(x_position: 4, y_position: 5)
        white_knight.update_attributes(x_position: 2, y_position: 4)
        game.determine_check(black_king)
        expect(game.check?).to eq(true)
      end
      it "should be held in check by white Pawn" do
        black_king = game.kings.where(color: false).take
        white_pawn = game.pawns.where(color: true).first
        black_king.update_attributes(x_position: 4, y_position: 5)
        white_pawn.update_attributes(x_position: 3, y_position: 4)
        game.determine_check(black_king)
        expect(game.check?).to eq(true)
      end
      it "should not be held in check by white Pawn" do
        black_king = game.kings.where(color: false).take
        white_pawn = game.pawns.where(color: true).first
        black_king.update_attributes(x_position: 4, y_position: 5)
        white_pawn.update_attributes(x_position: 4, y_position: 4)
        game.determine_check(black_king)
        expect(game.check?).to eq(false)
      end
      it "should be held in check by white Queen" do
        black_king = game.kings.where(color: false).take
        white_queen = game.queens.where(color: true).take
        black_king.update_attributes(x_position: 4, y_position: 5)
        white_queen.update_attributes(x_position: 1, y_position: 2)
        game.determine_check(black_king)
        expect(game.check?).to eq(true)
      end
      it "should be held in check by white Rook" do
        black_king = game.kings.where(color: false).take
        white_rook = game.rooks.where(color: true).first
        black_king.update_attributes(x_position: 4, y_position: 5)
        white_rook.update_attributes(x_position: 4, y_position: 2)
        game.determine_check(black_king)
        expect(game.check?).to eq(true)
      end
      it "should be held in check by white Bishop" do
        black_king = game.kings.where(color: false).take
        white_bishop = game.bishops.where(color: true).first
        black_king.update_attributes(x_position: 4, y_position: 5)
        white_bishop.update_attributes(x_position: 7, y_position: 2)
        game.determine_check(black_king)
        expect(game.check?).to eq(true)
      end
      it "should be held in check by white King" do
        black_king = game.kings.where(color: false).take
        white_king = game.kings.where(color: true).take
        black_king.update_attributes(x_position: 4, y_position: 4)
        white_king.update_attributes(x_position: 3, y_position: 3)
        game.determine_check(black_king)
        expect(game.check?).to eq(true)
      end
      it "should NOT be held in check by white King" do
        black_king = game.kings.where(color: false).take
        white_king = game.kings.where(color: true).take
        black_king.update_attributes(x_position: 4, y_position: 4)
        white_king.update_attributes(x_position: 5, y_position: 2)
        game.determine_check(black_king)
        expect(game.check?).to eq(false)
      end
    end
  end

  describe "is in check?" do
    it "should be false when check_status is 0" do
      game.update_attributes(check_status: 0)
      expect(game.check?).to eq(false)
    end
    it "should be true when check_status is 1" do
      game.update_attributes(check_status: 1)
      expect(game.check?).to eq(true)
    end
  end

  describe "range_between_pieces" do
    before :each do
      @game = FactoryGirl.create(:game)
      @game.pieces.delete_all
    end
    context "horizontal range" do
      it "returns empty for adjacent squares" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 3, y_position: 4)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 4, y_position: 4)
        expect(@game.range_between_pieces(black_king, white_queen).empty?).to be true
        expect(@game.range_between_pieces(white_queen, black_king).empty?).to be true
      end
      it "returns 1 for squares 2 away" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 2, y_position: 4)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 4, y_position: 4)
        expect(@game.range_between_pieces(black_king, white_queen)).to contain_exactly([3, 4])
        expect(@game.range_between_pieces(white_queen, black_king)).to contain_exactly([3, 4])
      end
      it "returns 2 for squares 3 away" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 1, y_position: 4)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 4, y_position: 4)
        expect(@game.range_between_pieces(black_king, white_queen)).to contain_exactly([2, 4],[3, 4])
        expect(@game.range_between_pieces(white_queen, black_king)).to contain_exactly([2, 4],[3, 4])
      end
    end
    context "vertical range" do
      it "returns empty for adjacent squares" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 4, y_position: 3)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 4, y_position: 4)
        expect(@game.range_between_pieces(black_king, white_queen).empty?).to be true
        expect(@game.range_between_pieces(white_queen, black_king).empty?).to be true
      end
      it "returns 1 for squares 2 away" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 4, y_position: 2)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 4, y_position: 4)
        expect(@game.range_between_pieces(black_king, white_queen)).to contain_exactly([4, 3])
        expect(@game.range_between_pieces(white_queen, black_king)).to contain_exactly([4, 3])
      end
      it "returns 2 for squares 3 away" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 4, y_position: 1)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 4, y_position: 4)
        expect(@game.range_between_pieces(black_king, white_queen)).to contain_exactly([4, 2],[4, 3])
        expect(@game.range_between_pieces(white_queen, black_king)).to contain_exactly([4, 2],[4, 3])
      end
    end
    context "diagonal range" do
      it "returns empty for adjacent squares NE-SW" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 3, y_position: 3)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 4, y_position: 4)
        expect(@game.range_between_pieces(black_king, white_queen).empty?).to be true
        expect(@game.range_between_pieces(white_queen, black_king).empty?).to be true
      end
      it "returns empty for adjacent squares NW-SE" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 3, y_position: 3)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 2, y_position: 4)
        expect(@game.range_between_pieces(black_king, white_queen).empty?).to be true
        expect(@game.range_between_pieces(white_queen, black_king).empty?).to be true
      end
      it "returns 1 for squares 2 away NE-SW" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 3, y_position: 3)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 5, y_position: 5)
        expect(@game.range_between_pieces(black_king, white_queen)).to contain_exactly([4, 4])
        expect(@game.range_between_pieces(white_queen, black_king)).to contain_exactly([4, 4])
      end
      it "returns 1 for squares 2 away NW-SE" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 3, y_position: 3)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 1, y_position: 5)
        expect(@game.range_between_pieces(black_king, white_queen)).to contain_exactly([2, 4])
        expect(@game.range_between_pieces(white_queen, black_king)).to contain_exactly([2, 4])
      end
      it "returns 2 for squares 3 away NE-SW" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 3, y_position: 3)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 6, y_position: 6)
        expect(@game.range_between_pieces(black_king, white_queen)).to contain_exactly([4, 4],[5, 5])
        expect(@game.range_between_pieces(white_queen, black_king)).to contain_exactly([4, 4],[5, 5])
      end
      it "returns 2 for squares 3 away NW-SE" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 3, y_position: 3)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 0, y_position: 6)
        expect(@game.range_between_pieces(black_king, white_queen)).to contain_exactly([2, 4],[1, 5])
        expect(@game.range_between_pieces(white_queen, black_king)).to contain_exactly([2, 4],[1, 5])
      end
    end
    context "same square passed" do
      it "returns empty if same square" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 3, y_position: 3)
        expect(@game.range_between_pieces(black_king, black_king).empty?).to be true
      end
    end
    context "invalid range (not vertical, horizontal, or diagonal" do
      it "returns nil if invalid range" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 0, y_position: 0)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 6, y_position: 7)
        expect(@game.range_between_pieces(black_king, white_queen)).to be nil
        expect(@game.range_between_pieces(white_queen, black_king)).to be nil
      end
    end
  end

  describe "checkmate?" do
    before :each do
      @game = FactoryGirl.create(:game)
      @game.pieces.delete_all
    end
    context "is in checkmate" do
      it "if in check and no valid moves to get out - example 1" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 4, y_position: 7)
        white_rook1 = Rook.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 1, y_position: 6)
        white_rook2 = Rook.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 1, y_position: 7)
        expect(@game.checkmate?(black_king)).to eq true
      end
      it "if in check and no valid moves to get out - example 2" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 3, y_position: 3)
        black_queen = Queen.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 7, y_position: 4)
        white_rook1 = Rook.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 2, y_position: 2)
        white_rook2 = Rook.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 3, y_position: 5)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 5, y_position: 5)
        white_knight = Knight.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 6, y_position: 2)
        expect(@game.checkmate?(black_king)).to eq true
      end
      it "if in check and no valid moves to get out - example 3" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 1, y_position: 0)
        black_pawn = Pawn.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 0, y_position: 1)
        black_rook = Rook.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 0, y_position: 0)
        black_bishop = Bishop.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 2, y_position: 0)
        white_knight = Knight.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 2, y_position: 2)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 4, y_position: 1)
        expect(@game.checkmate?(black_king)).to eq true
      end
      it "if in check and no valid moves to get out - example 4" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 1, y_position: 0)
        black_pawn = Pawn.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 0, y_position: 1)
        black_rook = Rook.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 0, y_position: 0)
        black_queen = Queen.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 2, y_position: 0)
        white_knight = Knight.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 2, y_position: 2)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 4, y_position: 1)
        white_rook = Rook.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 4, y_position: 0)
        expect(@game.checkmate?(black_king)).to eq true
      end
      it "if in check and no valid moves to get out - example 5" do
        white_king = King.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 0, y_position: 0)
        black_queen = Queen.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 1, y_position: 1)
        black_pawn = Pawn.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 2, y_position: 2)
        expect(@game.checkmate?(white_king)).to eq true # pawns must be on correct side of board!
      end
      it "if in check and no valid moves to get out - example 6" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 0, y_position: 0)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 2, y_position: 3)
        white_bishop1 = Bishop.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 2, y_position: 2)
        white_bishop2 = Bishop.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 2, y_position: 1)
        expect(@game.checkmate?(black_king)).to eq true
      end
      it "if in check and no valid moves to get out - example 7" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 2, y_position: 0)
        black_rook = Rook.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 5, y_position: 3)
        white_rook1 = Rook.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 0, y_position: 1)
        white_rook2 = Rook.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 5, y_position: 0)
        white_bishop = Bishop.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 4, y_position: 2)
        expect(@game.checkmate?(black_king)).to eq true
      end
    end
    context "is not in checkmate" do
      it "if in check and can move king out" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 4, y_position: 7)
        white_rook = Rook.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 1, y_position: 7)
        expect(@game.checkmate?(black_king)).to eq false
      end
      it "if in check and can move a friendly piece to block - example 1" do
        # black queen can block black king from being in check from white rooks
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 4, y_position: 7)
        white_rook1 = Rook.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 1, y_position: 6)
        white_rook2 = Rook.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 1, y_position: 7)
        black_queen = Queen.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 3, y_position: 3)
        expect(@game.checkmate?(black_king)).to eq false
      end
      it "if in check and can move a friendly piece to block - example 2" do
        # black bishop can capture white queen and block white bishop from putting king in check
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 0, y_position: 0)
        black_bishop = Bishop.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 2, y_position: 0)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 1, y_position: 1)
        white_bishop = Bishop.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 2, y_position: 2)
        expect(@game.checkmate?(black_king)).to eq false
        expect(white_queen.captured?).to eq false # make sure piece isn't actually captured by the test
      end
      it "if in check and can move a friendly piece to block - example 3" do
        # black rook can move down to black king and block white rook's check
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 2, y_position: 0)
        black_rook = Rook.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 3, y_position: 3)
        white_rook1 = Rook.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 5, y_position: 0)
        white_rook2 = Rook.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 0, y_position: 1)
        expect(@game.checkmate?(black_king)).to eq false
      end
      it "if in check and king can capture threatening piece - example 1" do
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 4, y_position: 7)
        white_rook1 = Rook.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 1, y_position: 6)
        white_rook2 = Rook.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 3, y_position: 7)
        expect(@game.checkmate?(black_king)).to eq false
        expect(white_rook2.captured?).to eq false # make sure piece isn't actually captured by the test
      end
      it "if in check and king can capture threatening piece - example 2" do
        # king can capture queen
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 0, y_position: 0)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 1, y_position: 1)
        expect(@game.checkmate?(black_king)).to eq false
        expect(white_queen.captured?).to eq false # make sure piece isn't actually captured by the test
      end
      it "if in check and king can capture threatening piece - example 3" do
        # black king can capture white queen putting it in check and move out of white knight check
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 0, y_position: 0)
        black_pawn = Pawn.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 0, y_position: 1)
        black_knight = Knight.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 1, y_position: 0)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 1, y_position: 1)
        white_knight = Knight.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 1, y_position: 2)
        expect(@game.checkmate?(black_king)).to eq false
        expect(white_queen.captured?).to eq false # make sure piece isn't actually captured by the test
      end
      it "if not in check" do
        # can't be checkmate if not in check
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 4, y_position: 7)
        white_rook = Rook.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 1, y_position: 6)
        expect(@game.checkmate?(black_king)).to eq false
      end
      it "if in check and friendly piece can capture threatening piece - example 1" do
        # black pawn can capture white knight
        white_king = King.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 1, y_position: 0)
        white_pawn1 = Pawn.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 0, y_position: 1)
        white_pawn2 = Pawn.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 1, y_position: 1)
        white_pawn3 = Pawn.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 2, y_position: 1)
        white_rook = Rook.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 0, y_position: 0)
        white_bishop = Bishop.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 2, y_position: 0)
        black_knight = Knight.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 2, y_position: 2)
        expect(@game.checkmate?(white_king)).to eq false # pawns have to be on the correct side!
        expect(black_knight.captured?).to eq false # make sure piece isn't actually captured by the test
      end
      it "if in check and friendly piece can capture threatening piece - example 2" do
        # black queen can capture white knight
        white_king = King.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 1, y_position: 0)
        white_pawn = Pawn.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 0, y_position: 1)
        white_rook = Rook.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 0, y_position: 0)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 2, y_position: 0)
        black_knight = Knight.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 2, y_position: 2)
        black_queen = Queen.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 4, y_position: 1)
        expect(@game.checkmate?(white_king)).to eq false # pawns have to be on the correct side!
        expect(black_knight.captured?).to eq false # make sure piece isn't actually captured by the test
      end
      it "if in check and friendly piece can capture threatening piece - example 3" do
        # black rook can capture white rook which has black king in check
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 2, y_position: 0)
        black_rook = Rook.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 5, y_position: 3)
        white_rook1 = Rook.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 0, y_position: 1)
        white_rook2 = Rook.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 5, y_position: 0)
        expect(@game.checkmate?(black_king)).to eq false
        expect(white_rook2.captured?).to eq false # make sure piece isn't actually captured by the test
      end
      it "if in check and friendly piece can capture threatening piece - example 4" do
        # black knight can capture white bishop which has black king in check
        black_king = King.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 0, y_position: 0)
        black_knight = Knight.create(color: false, game_id: @game.id, user_id: @game.black_user_id, x_position: 3, y_position: 0)
        white_bishop1 = Bishop.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 2, y_position: 1)
        white_bishop2 = Bishop.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 2, y_position: 2)
        white_queen = Queen.create(color: true, game_id: @game.id, user_id: @game.white_user_id, x_position: 2, y_position: 3)
        expect(@game.checkmate?(black_king)).to eq false
        expect(white_bishop2.captured?).to eq false # make sure piece isn't actually captured by the test
      end
    end
  end
end
