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

ActiveRecord::Schema.define(version: 20170131214021) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "aid_stations", force: :cascade do |t|
    t.integer  "event_id"
    t.integer  "split_id"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.datetime "open_time"
    t.datetime "close_time"
    t.integer  "status"
    t.string   "captain_name"
    t.string   "comms_crew_names"
    t.string   "comms_frequencies"
    t.string   "current_issues"
    t.integer  "import_sequence_id", default: 0
  end

  add_index "aid_stations", ["event_id"], name: "index_aid_stations_on_event_id", using: :btree
  add_index "aid_stations", ["split_id"], name: "index_aid_stations_on_split_id", using: :btree

  create_table "connections", force: :cascade do |t|
    t.integer  "user_id",                    null: false
    t.integer  "participant_id",             null: false
    t.integer  "kind",           default: 0, null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "connections", ["participant_id"], name: "index_connections_on_participant_id", using: :btree
  add_index "connections", ["user_id", "participant_id"], name: "index_connections_on_user_id_and_participant_id", unique: true, using: :btree
  add_index "connections", ["user_id"], name: "index_connections_on_user_id", using: :btree

  create_table "courses", force: :cascade do |t|
    t.string   "name",            limit: 64, null: false
    t.text     "description"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "next_start_time"
  end

  create_table "efforts", force: :cascade do |t|
    t.integer  "event_id",                                    null: false
    t.integer  "participant_id"
    t.string   "wave"
    t.integer  "bib_number"
    t.string   "city",             limit: 64
    t.string   "state_code",       limit: 64
    t.integer  "age"
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "gender"
    t.string   "country_code",     limit: 2
    t.date     "birthdate"
    t.integer  "data_status"
    t.integer  "start_offset",                default: 0
    t.integer  "dropped_split_id"
    t.boolean  "concealed",                   default: false
    t.string   "beacon_url"
    t.string   "report_url"
    t.string   "photo_url"
    t.integer  "dropped_lap"
  end

  add_index "efforts", ["event_id"], name: "index_efforts_on_event_id", using: :btree
  add_index "efforts", ["participant_id"], name: "index_efforts_on_participant_id", using: :btree

  create_table "events", force: :cascade do |t|
    t.integer  "course_id",                                 null: false
    t.integer  "race_id"
    t.string   "name",           limit: 64,                 null: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "start_time"
    t.boolean  "concealed",                 default: false
    t.boolean  "available_live",            default: false
    t.string   "beacon_url"
    t.integer  "laps_required"
  end

  add_index "events", ["course_id"], name: "index_events_on_course_id", using: :btree
  add_index "events", ["race_id"], name: "index_events_on_race_id", using: :btree

  create_table "locations", force: :cascade do |t|
    t.string   "name",        limit: 64,                         null: false
    t.text     "description"
    t.float    "elevation"
    t.decimal  "latitude",               precision: 9, scale: 6
    t.decimal  "longitude",              precision: 9, scale: 6
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
    t.integer  "created_by"
    t.integer  "updated_by"
  end

  create_table "participants", force: :cascade do |t|
    t.string   "first_name",   limit: 32,                 null: false
    t.string   "last_name",    limit: 64,                 null: false
    t.integer  "gender",                                  null: false
    t.date     "birthdate"
    t.string   "city"
    t.string   "state_code"
    t.string   "email"
    t.string   "phone"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "country_code", limit: 2
    t.integer  "user_id"
    t.boolean  "concealed",               default: false
    t.string   "photo_url"
  end

  add_index "participants", ["user_id"], name: "index_participants_on_user_id", using: :btree

  create_table "races", force: :cascade do |t|
    t.string   "name",        limit: 64,                 null: false
    t.text     "description"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.boolean  "concealed",              default: false
  end

  create_table "split_times", force: :cascade do |t|
    t.integer  "effort_id",        null: false
    t.integer  "split_id",         null: false
    t.float    "time_from_start",  null: false
    t.integer  "data_status"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "sub_split_bitkey"
    t.boolean  "pacer"
    t.string   "remarks"
    t.integer  "lap"
  end

  add_index "split_times", ["effort_id", "lap", "split_id", "sub_split_bitkey"], name: "index_split_times_on_effort_id_and_time_point", unique: true, using: :btree
  add_index "split_times", ["effort_id"], name: "index_split_times_on_effort_id", using: :btree
  add_index "split_times", ["split_id"], name: "index_split_times_on_split_id", using: :btree
  add_index "split_times", ["sub_split_bitkey"], name: "index_split_times_on_sub_split_bitkey", using: :btree

  create_table "splits", force: :cascade do |t|
    t.integer  "course_id",                        null: false
    t.integer  "location_id"
    t.integer  "distance_from_start",              null: false
    t.float    "vert_gain_from_start"
    t.float    "vert_loss_from_start"
    t.integer  "kind",                             null: false
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "description"
    t.string   "base_name"
    t.integer  "sub_split_bitmap",     default: 1
  end

  add_index "splits", ["course_id"], name: "index_splits_on_course_id", using: :btree
  add_index "splits", ["location_id"], name: "index_splits_on_location_id", using: :btree

  create_table "stewardships", force: :cascade do |t|
    t.integer  "user_id",                null: false
    t.integer  "race_id",                null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "level",      default: 0
  end

  add_index "stewardships", ["race_id"], name: "index_stewardships_on_race_id", using: :btree
  add_index "stewardships", ["user_id", "race_id"], name: "index_stewardships_on_user_id_and_race_id", unique: true, using: :btree
  add_index "stewardships", ["user_id"], name: "index_stewardships_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "first_name",             limit: 32,              null: false
    t.string   "last_name",              limit: 64,              null: false
    t.integer  "role"
    t.string   "provider"
    t.string   "uid"
    t.string   "email",                             default: "", null: false
    t.string   "encrypted_password",                default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                     default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
    t.integer  "pref_distance_unit",                default: 0,  null: false
    t.integer  "pref_elevation_unit",               default: 0,  null: false
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  add_foreign_key "aid_stations", "events"
  add_foreign_key "aid_stations", "splits"
  add_foreign_key "connections", "participants"
  add_foreign_key "connections", "users"
  add_foreign_key "efforts", "events"
  add_foreign_key "efforts", "participants"
  add_foreign_key "events", "courses"
  add_foreign_key "events", "races"
  add_foreign_key "participants", "users"
  add_foreign_key "split_times", "efforts"
  add_foreign_key "split_times", "splits"
  add_foreign_key "splits", "courses"
  add_foreign_key "splits", "locations"
  add_foreign_key "stewardships", "races"
  add_foreign_key "stewardships", "users"
end
