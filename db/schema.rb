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

ActiveRecord::Schema.define(version: 6) do

  create_table "candle_sticks", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "from", null: false
    t.datetime "to", null: false
    t.string "pair", null: false
    t.string "time_frame", null: false
    t.float "open", null: false
    t.float "close", null: false
    t.float "high", null: false
    t.float "low", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from", "to", "pair", "time_frame"], name: "index_candle_sticks_on_from_and_to_and_pair_and_time_frame", unique: true
    t.index ["to"], name: "index_candle_sticks_on_to"
  end

  create_table "moving_averages", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "time", null: false
    t.string "pair", null: false
    t.string "time_frame", null: false
    t.integer "period", null: false
    t.float "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["time", "pair", "time_frame", "period"], name: "index_moving_averages_on_time_and_pair_and_time_frame_and_period", unique: true
    t.index ["time"], name: "index_moving_averages_on_time"
  end

  create_table "rates", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "time", null: false
    t.string "pair", null: false
    t.float "bid", null: false
    t.float "ask", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["time", "pair"], name: "index_rates_on_time_and_pair", unique: true
    t.index ["time"], name: "index_rates_on_time"
  end

end
