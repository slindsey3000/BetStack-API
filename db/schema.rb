# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_11_02_212327) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bookmakers", force: :cascade do |t|
    t.string "key", null: false
    t.string "name", null: false
    t.text "description"
    t.string "region"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_bookmakers_on_key", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.bigint "league_id", null: false
    t.bigint "home_team_id", null: false
    t.bigint "away_team_id", null: false
    t.string "odds_api_id", null: false
    t.string "home_team_name"
    t.string "away_team_name"
    t.datetime "commence_time"
    t.string "status"
    t.boolean "completed", default: false
    t.boolean "preseason", default: false
    t.datetime "last_sync_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["away_team_id"], name: "index_events_on_away_team_id"
    t.index ["commence_time"], name: "index_events_on_commence_time"
    t.index ["home_team_id"], name: "index_events_on_home_team_id"
    t.index ["league_id"], name: "index_events_on_league_id"
    t.index ["odds_api_id"], name: "index_events_on_odds_api_id", unique: true
  end

  create_table "leagues", force: :cascade do |t|
    t.bigint "sport_id", null: false
    t.string "name"
    t.string "key", null: false
    t.string "region"
    t.boolean "active", default: true
    t.boolean "has_outrights", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_leagues_on_key", unique: true
    t.index ["sport_id"], name: "index_leagues_on_sport_id"
  end

  create_table "lines", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "bookmaker_id", null: false
    t.string "source", default: "the-odds-api"
    t.string "odd_type"
    t.decimal "money_line_home", precision: 10, scale: 2
    t.decimal "money_line_away", precision: 10, scale: 2
    t.decimal "draw_line", precision: 10, scale: 2
    t.decimal "point_spread_home", precision: 8, scale: 2
    t.decimal "point_spread_away", precision: 8, scale: 2
    t.decimal "point_spread_home_line", precision: 10, scale: 2
    t.decimal "point_spread_away_line", precision: 10, scale: 2
    t.decimal "total_number", precision: 8, scale: 2
    t.decimal "over_line", precision: 10, scale: 2
    t.decimal "under_line", precision: 10, scale: 2
    t.datetime "last_updated"
    t.jsonb "participant_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bookmaker_id"], name: "index_lines_on_bookmaker_id"
    t.index ["event_id", "bookmaker_id"], name: "index_lines_on_event_id_and_bookmaker_id", unique: true
    t.index ["event_id"], name: "index_lines_on_event_id"
  end

  create_table "results", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.integer "home_score"
    t.integer "away_score"
    t.boolean "final", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["event_id"], name: "index_results_on_event_id", unique: true
  end

  create_table "sports", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "teams", force: :cascade do |t|
    t.bigint "league_id", null: false
    t.string "name", null: false
    t.string "normalized_name"
    t.string "abbreviation"
    t.string "city"
    t.string "conference"
    t.string "division"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["league_id", "normalized_name"], name: "index_teams_on_league_id_and_normalized_name", unique: true
    t.index ["league_id"], name: "index_teams_on_league_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "api_key", null: false
    t.string "email", null: false
    t.string "phone_number", null: false
    t.text "address"
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_key"], name: "index_users_on_api_key", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
  end

  add_foreign_key "events", "leagues"
  add_foreign_key "events", "teams", column: "away_team_id"
  add_foreign_key "events", "teams", column: "home_team_id"
  add_foreign_key "leagues", "sports"
  add_foreign_key "lines", "bookmakers"
  add_foreign_key "lines", "events"
  add_foreign_key "results", "events", name: "results_event_id_fkey"
  add_foreign_key "teams", "leagues"
end
