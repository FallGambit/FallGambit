require 'rails_helper'

RSpec.describe Knight, type: :model do
  def find_piece(x, y)
    @game.pieces.where("x_position = ? AND y_position = ?", x, y).take
  end

  describe 'valid_move?' do
    before :all do
      @game = FactoryGirl.create(:game)
      @bknight1 = find_piece(1, 0)
      @bknight2 = find_piece(6, 0)
      @wknight1 = find_piece(1, 7)
      @wknight2 = find_piece(6, 7)
      @bpawn1 = find_piece(0, 1)
      @bpawn1.update(y_position: 2)
      @bpawn4 = find_piece(3, 1)
      @bpawn5 = find_piece(4, 1)
      @bpawn8 = find_piece(7, 1)
      @bpawn8.update(y_position: 2)
      @wpawn1 = find_piece(0, 6)
      @wpawn1.update(y_position: 5)
      @wpawn4 = find_piece(3, 6)
      @wpawn5 = find_piece(4, 6)
      @wpawn8 = find_piece(7, 6)
      @wpawn8.update(y_position: 5)
    end

    context "invalid move cases all false" do
      it 'will be false S4W4 (delta too large)' do
        expect(@bknight1.valid_move?(4, 4)).to eq false
      end

      it 'will be false S1W1 (delta too small)' do
        expect(@bknight2.valid_move?(7, 1)).to eq false
      end

      it 'will be false N1W1 (delta too small)' do
        expect(@wknight1.valid_move?(0, 6)).to eq false
      end

      it 'will be false N4 (delta X too big, no delta Y)' do
        expect(@wknight2.valid_move?(6, 3)).to eq false
      end

      it 'will be false to move off board' do
        expect(@bknight2.valid_move?(8, 1)).to eq false
      end
    end

    context "same-color obstructions all false" do
      it 'will be false S2W1 same-color obstruction' do
        expect(@bknight1.valid_move?(0, 2)).to eq false
      end

      it 'will be false S2E1 same-color obstruction' do
        expect(@bknight2.valid_move?(7, 2)).to eq false
      end

      it 'will be false S1E2 same-color obstruction' do
        expect(@bknight1.valid_move?(3, 1)).to eq false
      end

      it 'will be false S1W2 same-color obstruction' do
        expect(@bknight2.valid_move?(4, 1)).to eq false
      end

      it 'will be false N2W1 same-color obstruction' do
        expect(@wknight1.valid_move?(0, 5)).to eq false
      end

      it 'will be false N2E1 same-color obstruction' do
        expect(@wknight2.valid_move?(7, 5)).to eq false
      end

      it 'will be false N1E2 same-color obstruction' do
        expect(@wknight1.valid_move?(3, 6)).to eq false
      end

      it 'will be false N1W2 same-color obstruction' do
        expect(@wknight2.valid_move?(4, 6)).to eq false
      end
    end

    context "opposite-color obstructions all true" do
      before :all do
        @bpawn1.update(image_name: "white-pawn.png", color: true)
        @bpawn4.update(image_name: "white-pawn.png", color: true)
        @bpawn5.update(image_name: "white-pawn.png", color: true)
        @bpawn8.update(image_name: "white-pawn.png", color: true)
        @wpawn1.update(image_name: "black-pawn.png", color: false)
        @wpawn4.update(image_name: "black-pawn.png", color: false)
        @wpawn5.update(image_name: "black-pawn.png", color: false)
        @wpawn8.update(image_name: "black-pawn.png", color: false)
      end

      it 'will be true S1E2 opposite-color obstruction' do
        expect(@bknight1.valid_move?(3, 1)).to eq true
      end

      it 'will be true S1W2 opposite-color obstruction' do
        expect(@bknight2.valid_move?(4, 1)).to eq true
      end

      it 'will be true S2W1 opposite-color obstruction' do
        expect(@bknight1.valid_move?(0, 2)).to eq true
      end

      it 'will be true S2E1 opposite-color obstruction' do
        expect(@bknight2.valid_move?(7, 2)).to eq true
      end

      it 'will be true N2W1 opposite-color obstruction' do
        expect(@wknight1.valid_move?(0, 5)).to eq true
      end

      it 'will be true N2E1 opposite-color obstruction' do
        expect(@wknight2.valid_move?(7, 5)).to eq true
      end

      it 'will be true N1E2 opposite-color obstruction' do
        expect(@wknight1.valid_move?(3, 6)).to eq true
      end

      it 'will be true N1W2 opposite-color obstruction' do
        expect(@wknight2.valid_move?(4, 6)).to eq true
      end
    end

    context "no obstruction all true" do
      before :all do
        @bpawn4.update(y_position: 2)
        @bpawn5.update(y_position: 2)
        @wpawn4.update(y_position: 5)
        @wpawn5.update(y_position: 5)
      end

      it 'will be true S2E1 no obstruction' do
        expect(@bknight1.valid_move?(2, 2)).to eq true
      end

      it 'will be true S2W1 no obstruction' do
        expect(@bknight2.valid_move?(5, 2)).to eq true
      end

      it 'will be true S1E2 no obstruction' do
        expect(@bknight1.valid_move?(3, 1)).to eq true
      end

      it 'will be true S1W2 no obstruction' do
        expect(@bknight2.valid_move?(4, 1)).to eq true
      end

      it 'will be true N1E2 no obstruction' do
        expect(@wknight1.valid_move?(3, 6)).to eq true
      end

      it 'will be true N1W2 no obstruction' do
        expect(@wknight2.valid_move?(4, 6)).to eq true
      end

      it 'will be true N2E1 no obstruction' do
        expect(@wknight1.valid_move?(2, 5)).to eq true
      end

      it 'will be true N2W1 no obstruction' do
        expect(@wknight2.valid_move?(5, 5)).to eq true
      end
    end

    after :all do
      @game.pieces.delete_all
      @game.delete
    end
  end
end
