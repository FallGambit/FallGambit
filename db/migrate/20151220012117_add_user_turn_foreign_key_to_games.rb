class AddUserTurnForeignKeyToGames < ActiveRecord::Migration
  def up
    add_foreign_key "games", "users", name: "games_user_turn_fk", column: "user_turn"
  end

  def down
    change_table :games do |t|
      t.remove_foreign_key name: "games_user_turn_fk"
    end
  end
end
