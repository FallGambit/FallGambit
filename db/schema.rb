# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151225120113) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "games", force: true do |t|
    t.string   "game_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_turn"
    t.integer  "check_status"
    t.integer  "white_user_id"
    t.integer  "black_user_id"
    t.integer  "game_winner"
    t.integer  "last_moved_piece_id"
    t.integer  "last_moved_prev_x_pos"
    t.integer  "last_moved_prev_y_pos"
  end

  add_index "games", ["black_user_id"], name: "index_games_on_black_user_id", using: :btree
  add_index "games", ["white_user_id"], name: "index_games_on_white_user_id", using: :btree

  create_table "pieces", force: true do |t|
    t.integer  "x_position"
    t.integer  "y_position"
    t.string   "piece_type"
    t.boolean  "color"
    t.integer  "game_id"
    t.integer  "user_id"
    t.boolean  "captured",   default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "image_name"
    t.boolean  "has_moved",  default: false
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  add_foreign_key "games", "pieces", name: "games_last_moved_piece_fk", column: "last_moved_piece_id"
  add_foreign_key "games", "users", name: "games_black_user_id_fk", column: "black_user_id"
  add_foreign_key "games", "users", name: "games_game_winner_fk", column: "game_winner"
  add_foreign_key "games", "users", name: "games_user_turn_fk", column: "user_turn"
  add_foreign_key "games", "users", name: "games_white_user_id_fk", column: "white_user_id"

  add_foreign_key "pieces", "games", name: "pieces_game_id_fk", dependent: :delete
  add_foreign_key "pieces", "users", name: "pieces_user_id_fk"

end
