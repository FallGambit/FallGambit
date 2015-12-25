class AddGameWinnerToGames < ActiveRecord::Migration
  def up
    add_column :games, :game_winner, :integer
    add_foreign_key "games", "users", name: "games_game_winner_fk", column: "game_winner"
  end

  def down
    change_table :games do |t|
      t.remove_foreign_key name: "games_game_winner_fk"
    end
    remove_column :games, :game_winner, :integer
  end
end
