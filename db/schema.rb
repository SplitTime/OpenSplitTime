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

ActiveRecord::Schema.define(version: 20151017202621) do

  create_table "courses", force: :cascade do |t|
    t.integer  "course_id"
    t.string   "course_name"
    t.integer  "start_elevation"
    t.string   "start_location_name"
    t.string   "end_location_name"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

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

end
