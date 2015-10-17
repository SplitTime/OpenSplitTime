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

ActiveRecord::Schema.define(version: 20151017211328) do

  create_table "courses", force: :cascade do |t|
    t.integer  "course_id"
    t.string   "course_name"
    t.integer  "start_elevation"
    t.string   "start_location_name"
    t.string   "end_location_name"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  create_table "efforts", force: :cascade do |t|
    t.integer  "effort_id"
    t.integer  "event_id"
    t.integer  "participant_id"
    t.string   "wave"
    t.integer  "bib_number"
    t.string   "effort_city"
    t.string   "effort_state"
    t.string   "effort_country"
    t.integer  "effort_age"
    t.datetime "start_time"
    t.boolean  "official_finish"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "efforts", ["effort_id"], name: "index_efforts_on_effort_id"
  add_index "efforts", ["event_id"], name: "index_efforts_on_event_id"
  add_index "efforts", ["participant_id"], name: "index_efforts_on_participant_id"

  create_table "events", force: :cascade do |t|
    t.integer  "event_id"
    t.string   "event_name"
    t.integer  "course_id"
    t.date     "start_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "events", ["course_id"], name: "index_events_on_course_id"
  add_index "events", ["event_id"], name: "index_events_on_event_id"

  create_table "participants", force: :cascade do |t|
    t.integer  "participant_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "gender"
    t.date     "birthdate"
    t.string   "home_city"
    t.string   "home_state"
    t.string   "home_country"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "participants", ["participant_id"], name: "index_participants_on_participant_id"

  create_table "split_times", force: :cascade do |t|
    t.integer  "splittime_id"
    t.integer  "effort_id"
    t.integer  "split_id"
    t.time     "time_from_start"
    t.integer  "data_status"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "split_times", ["effort_id"], name: "index_split_times_on_effort_id"
  add_index "split_times", ["split_id"], name: "index_split_times_on_split_id"
  add_index "split_times", ["splittime_id"], name: "index_split_times_on_splittime_id"

  create_table "splits", force: :cascade do |t|
    t.integer  "split_id"
    t.string   "split_name"
    t.integer  "course_id"
    t.integer  "split_order"
    t.integer  "vert_gain_from_start"
    t.integer  "vert_loss_from_start"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "splits", ["course_id"], name: "index_splits_on_course_id"
  add_index "splits", ["split_id"], name: "index_splits_on_split_id"

end
