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

ActiveRecord::Schema.define(version: 20180309161741) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"
  enable_extension "fuzzystrmatch"
  enable_extension "pg_trgm"

  create_table "aid_stations", id: :serial, force: :cascade do |t|
    t.integer "event_id"
    t.integer "split_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "open_time"
    t.datetime "close_time"
    t.integer "status"
    t.string "captain_name"
    t.string "comms_crew_names"
    t.string "comms_frequencies"
    t.string "current_issues"
    t.index ["event_id"], name: "index_aid_stations_on_event_id"
    t.index ["split_id"], name: "index_aid_stations_on_split_id"
  end

  create_table "courses", id: :serial, force: :cascade do |t|
    t.string "name", limit: 64, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "next_start_time"
    t.string "slug", null: false
    t.string "gpx_file_name"
    t.string "gpx_content_type"
    t.integer "gpx_file_size"
    t.datetime "gpx_updated_at"
    t.index ["slug"], name: "index_courses_on_slug", unique: true
  end

  create_table "efforts", id: :serial, force: :cascade do |t|
    t.integer "event_id", null: false
    t.integer "person_id"
    t.string "wave"
    t.integer "bib_number"
    t.string "city", limit: 64
    t.string "state_code", limit: 64
    t.integer "age"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.string "first_name"
    t.string "last_name"
    t.integer "gender"
    t.string "country_code", limit: 2
    t.date "birthdate"
    t.integer "data_status"
    t.integer "start_offset", default: 0, null: false
    t.string "beacon_url"
    t.string "report_url"
    t.string "phone", limit: 15
    t.string "email"
    t.string "slug", null: false
    t.boolean "checked_in", default: false
    t.string "photo_file_name"
    t.string "photo_content_type"
    t.integer "photo_file_size"
    t.datetime "photo_updated_at"
    t.string "emergency_contact"
    t.string "emergency_phone"
    t.index ["event_id"], name: "index_efforts_on_event_id"
    t.index ["person_id"], name: "index_efforts_on_person_id"
    t.index ["slug"], name: "index_efforts_on_slug", unique: true
  end

  create_table "event_groups", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "organization_id"
    t.boolean "available_live", default: false
    t.boolean "auto_live_times", default: false
    t.boolean "concealed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.string "slug"
    t.integer "data_entry_grouping_strategy", default: 0
    t.index ["organization_id"], name: "index_event_groups_on_organization_id"
    t.index ["slug"], name: "index_event_groups_on_slug", unique: true
  end

  create_table "events", id: :serial, force: :cascade do |t|
    t.integer "course_id", null: false
    t.string "name", limit: 64, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "start_time"
    t.string "beacon_url"
    t.integer "laps_required"
    t.string "slug", null: false
    t.string "home_time_zone", null: false
    t.integer "event_group_id"
    t.string "short_name"
    t.string "podium_template"
    t.boolean "monitor_pacers", default: false
    t.index ["course_id"], name: "index_events_on_course_id"
    t.index ["event_group_id"], name: "index_events_on_event_group_id"
    t.index ["slug"], name: "index_events_on_slug", unique: true
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "live_times", id: :serial, force: :cascade do |t|
    t.integer "event_id", null: false
    t.integer "split_id", null: false
    t.string "wave"
    t.string "bib_number", null: false
    t.datetime "absolute_time"
    t.boolean "with_pacer"
    t.boolean "stopped_here"
    t.string "remarks"
    t.string "batch"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.integer "split_time_id"
    t.integer "bitkey", null: false
    t.string "source", null: false
    t.integer "pulled_by"
    t.datetime "pulled_at"
    t.string "entered_time"
    t.index ["absolute_time", "event_id", "split_id", "bitkey", "bib_number", "source", "with_pacer", "stopped_here", "remarks"], name: "live_time_unique_absolute_times_index", unique: true
    t.index ["entered_time", "event_id", "split_id", "bitkey", "bib_number", "source", "with_pacer", "stopped_here", "remarks"], name: "live_time_unique_entered_times_index", unique: true
    t.index ["event_id"], name: "index_live_times_on_event_id"
    t.index ["split_id"], name: "index_live_times_on_split_id"
    t.index ["split_time_id"], name: "index_live_times_on_split_time_id"
  end

  create_table "locations", id: :serial, force: :cascade do |t|
    t.string "name", limit: 64, null: false
    t.text "description"
    t.float "elevation"
    t.decimal "latitude", precision: 9, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
  end

  create_table "organizations", id: :serial, force: :cascade do |t|
    t.string "name", limit: 64, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.boolean "concealed", default: false
    t.string "slug", null: false
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "partners", id: :serial, force: :cascade do |t|
    t.integer "event_id", null: false
    t.string "banner_link"
    t.integer "weight", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "banner_file_name"
    t.string "banner_content_type"
    t.integer "banner_file_size"
    t.datetime "banner_updated_at"
    t.string "name", null: false
    t.index ["event_id"], name: "index_partners_on_event_id"
  end

  create_table "people", id: :serial, force: :cascade do |t|
    t.string "first_name", limit: 32, null: false
    t.string "last_name", limit: 64, null: false
    t.integer "gender", null: false
    t.date "birthdate"
    t.string "city"
    t.string "state_code"
    t.string "email"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.string "country_code", limit: 2
    t.integer "user_id"
    t.boolean "concealed", default: false
    t.string "slug", null: false
    t.string "topic_resource_key"
    t.string "photo_file_name"
    t.string "photo_content_type"
    t.integer "photo_file_size"
    t.datetime "photo_updated_at"
    t.index ["slug"], name: "index_people_on_slug", unique: true
    t.index ["topic_resource_key"], name: "index_people_on_topic_resource_key", unique: true
    t.index ["user_id"], name: "index_people_on_user_id"
  end

  create_table "split_times", id: :serial, force: :cascade do |t|
    t.integer "effort_id", null: false
    t.integer "split_id", null: false
    t.float "time_from_start", null: false
    t.integer "data_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.integer "sub_split_bitkey"
    t.boolean "pacer"
    t.string "remarks"
    t.integer "lap"
    t.boolean "stopped_here", default: false
    t.index ["effort_id", "lap", "split_id", "sub_split_bitkey"], name: "index_split_times_on_effort_id_and_time_point", unique: true
    t.index ["effort_id"], name: "index_split_times_on_effort_id"
    t.index ["split_id"], name: "index_split_times_on_split_id"
    t.index ["sub_split_bitkey"], name: "index_split_times_on_sub_split_bitkey"
  end

  create_table "splits", id: :serial, force: :cascade do |t|
    t.integer "course_id", null: false
    t.integer "location_id"
    t.integer "distance_from_start", null: false
    t.float "vert_gain_from_start"
    t.float "vert_loss_from_start"
    t.integer "kind", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.string "description"
    t.string "base_name"
    t.integer "sub_split_bitmap", default: 1
    t.decimal "latitude", precision: 9, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.float "elevation"
    t.string "slug", null: false
    t.index ["course_id"], name: "index_splits_on_course_id"
    t.index ["location_id"], name: "index_splits_on_location_id"
    t.index ["slug"], name: "index_splits_on_slug", unique: true
  end

  create_table "stewardships", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "level", default: 0
    t.index ["organization_id"], name: "index_stewardships_on_organization_id"
    t.index ["user_id", "organization_id"], name: "index_stewardships_on_user_id_and_organization_id", unique: true
    t.index ["user_id"], name: "index_stewardships_on_user_id"
  end

  create_table "subscriptions", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "person_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "protocol", default: 0, null: false
    t.string "resource_key"
    t.index ["person_id"], name: "index_subscriptions_on_person_id"
    t.index ["resource_key"], name: "index_subscriptions_on_resource_key", unique: true
    t.index ["user_id", "person_id", "protocol"], name: "index_subscriptions_on_user_id_and_person_id_and_protocol", unique: true
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "first_name", limit: 32, null: false
    t.string "last_name", limit: 64, null: false
    t.integer "role"
    t.string "provider"
    t.string "uid"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "pref_distance_unit", default: 0, null: false
    t.integer "pref_elevation_unit", default: 0, null: false
    t.string "slug", null: false
    t.string "phone"
    t.string "http_endpoint"
    t.string "https_endpoint"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["slug"], name: "index_users_on_slug", unique: true
  end

  add_foreign_key "aid_stations", "events"
  add_foreign_key "aid_stations", "splits"
  add_foreign_key "efforts", "events"
  add_foreign_key "efforts", "people"
  add_foreign_key "event_groups", "organizations"
  add_foreign_key "events", "courses"
  add_foreign_key "events", "event_groups"
  add_foreign_key "live_times", "events"
  add_foreign_key "live_times", "split_times"
  add_foreign_key "live_times", "splits"
  add_foreign_key "partners", "events"
  add_foreign_key "people", "users"
  add_foreign_key "split_times", "efforts"
  add_foreign_key "split_times", "splits"
  add_foreign_key "splits", "courses"
  add_foreign_key "splits", "locations"
  add_foreign_key "stewardships", "organizations"
  add_foreign_key "stewardships", "users"
  add_foreign_key "subscriptions", "people"
  add_foreign_key "subscriptions", "users"
end
