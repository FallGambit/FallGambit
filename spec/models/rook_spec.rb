require 'rails_helper'

RSpec.describe Rook, type: :model do
  it "should be true when moving 1 space up" do
    board = create(:game)
    board.pieces.delete_all
    rook = Rook.create(x_position: 1, y_position: 0)
    board.reload
    actual = rook.valid_move?(1, 1)
    expect(actual).to be(true)
  end

  it "should be true when moving 2 spaces right" do
    board = create(:game)
    board.pieces.delete_all
    rook = Rook.create(x_position: 1, y_position: 0, game_id: board.id)
    board.reload
    actual = rook.valid_move?(3, 0)
    expect(actual).to be(true)
  end

  it "should be true when moving 3 spaces left" do
    board = create(:game)
    board.pieces.delete_all
    rook = Rook.create(x_position: 4, y_position: 3, game_id: board.id)
    board.reload
    actual = rook.valid_move?(1, 3)
    expect(actual).to be(true)
  end

  it "should be true when moving 4 spaces down" do
    board = create(:game)
    board.pieces.delete_all
    rook = Rook.create(x_position: 4, y_position: 4, game_id: board.id)
    board.reload
    actual = rook.valid_move?(4, 0)
    expect(actual).to be(true)
  end

  it "should be false when moving 1 space diagonal" do
    board = create(:game)
    board.pieces.delete_all
    rook = Rook.create(x_position: 1, y_position: 0, game_id: board.id)
    board.reload
    actual = rook.valid_move?(2, 1)
    expect(actual).to be(false)
  end

  it "should be false when moving 3 spaces diagonally" do
    board = create(:game)
    board.pieces.delete_all
    rook = Rook.create(x_position: 1, y_position: 0, game_id: board.id)
    board.reload
    actual = rook.valid_move?(4, 3)
    expect(actual).to be(false)
  end
end