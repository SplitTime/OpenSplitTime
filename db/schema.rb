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

ActiveRecord::Schema.define(version: 2020_08_14_040556) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "fuzzystrmatch"
  enable_extension "pg_trgm"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "aid_stations", id: :serial, force: :cascade do |t|
    t.integer "event_id"
    t.integer "split_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.bigint "organization_id"
    t.boolean "concealed"
    t.index ["organization_id"], name: "index_courses_on_organization_id"
    t.index ["slug"], name: "index_courses_on_slug", unique: true
  end

  create_table "effort_segments", id: false, force: :cascade do |t|
    t.integer "course_id"
    t.integer "begin_split_id"
    t.integer "begin_bitkey"
    t.integer "end_split_id"
    t.integer "end_bitkey"
    t.integer "effort_id"
    t.integer "lap"
    t.datetime "begin_time"
    t.datetime "end_time"
    t.integer "elapsed_seconds"
    t.integer "begin_split_kind"
    t.integer "end_split_kind"
    t.index ["begin_split_id", "begin_bitkey", "end_split_id", "end_bitkey", "effort_id", "lap"], name: "index_effort_segments_on_unique_attributes", unique: true
    t.index ["begin_split_id", "begin_bitkey", "end_split_id", "end_bitkey"], name: "index_effort_segments_on_sub_splits"
    t.index ["course_id"], name: "index_effort_segments_on_course_id"
    t.index ["effort_id"], name: "index_effort_segments_on_effort_id"
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
    t.string "beacon_url"
    t.string "report_url"
    t.string "phone", limit: 15
    t.string "email"
    t.string "slug", null: false
    t.boolean "checked_in", default: false
    t.string "emergency_contact"
    t.string "emergency_phone"
    t.datetime "scheduled_start_time"
    t.string "topic_resource_key"
    t.string "comments"
    t.index ["event_id"], name: "index_efforts_on_event_id"
    t.index ["person_id"], name: "index_efforts_on_person_id"
    t.index ["slug"], name: "index_efforts_on_slug", unique: true
    t.index ["topic_resource_key"], name: "index_efforts_on_topic_resource_key"
  end

  create_table "event_groups", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "organization_id"
    t.boolean "available_live", default: false
    t.boolean "concealed", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.string "slug"
    t.integer "data_entry_grouping_strategy", default: 0
    t.boolean "monitor_pacers", default: false
    t.string "home_time_zone"
    t.index ["organization_id"], name: "index_event_groups_on_organization_id"
    t.index ["slug"], name: "index_event_groups_on_slug", unique: true
  end

  create_table "event_series", force: :cascade do |t|
    t.bigint "organization_id"
    t.bigint "results_template_id"
    t.string "name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "scoring_method"
    t.index ["organization_id"], name: "index_event_series_on_organization_id"
    t.index ["results_template_id"], name: "index_event_series_on_results_template_id"
  end

  create_table "event_series_events", force: :cascade do |t|
    t.bigint "event_id"
    t.bigint "event_series_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_event_series_events_on_event_id"
    t.index ["event_series_id"], name: "index_event_series_events_on_event_series_id"
  end

  create_table "events", id: :serial, force: :cascade do |t|
    t.integer "course_id", null: false
    t.string "historical_name", limit: 64
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "start_time"
    t.string "beacon_url"
    t.integer "laps_required"
    t.string "slug", null: false
    t.integer "event_group_id"
    t.string "short_name"
    t.bigint "results_template_id", null: false
    t.integer "efforts_count", default: 0
    t.string "notice_text"
    t.index ["course_id"], name: "index_events_on_course_id"
    t.index ["event_group_id", "short_name"], name: "index_events_on_event_group_id_and_short_name", unique: true
    t.index ["event_group_id"], name: "index_events_on_event_group_id"
    t.index ["results_template_id"], name: "index_events_on_results_template_id"
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

  create_table "notifications", force: :cascade do |t|
    t.bigint "effort_id", null: false
    t.integer "distance", null: false
    t.integer "bitkey", null: false
    t.integer "follower_ids", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.integer "kind"
    t.string "topic_resource_key"
    t.string "subject"
    t.text "notice_text"
    t.index ["effort_id"], name: "index_notifications_on_effort_id"
  end

  create_table "organizations", id: :serial, force: :cascade do |t|
    t.string "name", limit: 64, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.boolean "concealed", default: true
    t.string "slug", null: false
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "partners", id: :serial, force: :cascade do |t|
    t.string "banner_link"
    t.integer "weight", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.bigint "event_group_id", null: false
    t.index ["event_group_id"], name: "index_partners_on_event_group_id"
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
    t.index ["slug"], name: "index_people_on_slug", unique: true
    t.index ["topic_resource_key"], name: "index_people_on_topic_resource_key", unique: true
    t.index ["user_id"], name: "index_people_on_user_id"
  end

  create_table "raw_times", force: :cascade do |t|
    t.bigint "event_group_id", null: false
    t.bigint "split_time_id"
    t.string "split_name", null: false
    t.integer "bitkey", null: false
    t.string "bib_number", null: false
    t.datetime "absolute_time"
    t.string "entered_time"
    t.boolean "with_pacer", default: false
    t.boolean "stopped_here", default: false
    t.string "source", null: false
    t.integer "pulled_by"
    t.datetime "pulled_at"
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "parameterized_split_name", null: false
    t.string "remarks"
    t.integer "sortable_bib_number", null: false
    t.integer "data_status"
    t.integer "matchable_bib_number"
    t.boolean "disassociated_from_effort"
    t.integer "entered_lap"
    t.index ["event_group_id"], name: "index_raw_times_on_event_group_id"
    t.index ["parameterized_split_name"], name: "index_raw_times_on_parameterized_split_name"
    t.index ["split_time_id"], name: "index_raw_times_on_split_time_id"
  end

  create_table "results_categories", force: :cascade do |t|
    t.bigint "organization_id"
    t.string "name"
    t.boolean "male"
    t.boolean "female"
    t.integer "low_age"
    t.integer "high_age"
    t.string "temp_key"
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_results_categories_on_organization_id"
  end

  create_table "results_template_categories", force: :cascade do |t|
    t.bigint "results_template_id"
    t.bigint "results_category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.index ["results_category_id"], name: "index_results_template_categories_on_results_category_id"
    t.index ["results_template_id"], name: "index_results_template_categories_on_results_template_id"
  end

  create_table "results_templates", force: :cascade do |t|
    t.bigint "organization_id"
    t.string "name"
    t.integer "aggregation_method"
    t.integer "podium_size"
    t.integer "point_system", default: [], array: true
    t.string "temp_key"
    t.string "slug", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_results_templates_on_organization_id"
  end

  create_table "shortened_urls", id: :serial, force: :cascade do |t|
    t.integer "owner_id"
    t.string "owner_type", limit: 20
    t.text "url", null: false
    t.string "unique_key", limit: 10, null: false
    t.string "category"
    t.integer "use_count", default: 0, null: false
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["category"], name: "index_shortened_urls_on_category"
    t.index ["owner_id", "owner_type"], name: "index_shortened_urls_on_owner_id_and_owner_type"
    t.index ["unique_key"], name: "index_shortened_urls_on_unique_key", unique: true
    t.index ["url"], name: "index_shortened_urls_on_url"
  end

  create_table "split_times", id: :serial, force: :cascade do |t|
    t.integer "effort_id", null: false
    t.integer "split_id", null: false
    t.integer "data_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.integer "sub_split_bitkey", null: false
    t.boolean "pacer"
    t.string "remarks"
    t.integer "lap", null: false
    t.boolean "stopped_here", default: false
    t.datetime "absolute_time", null: false
    t.float "elapsed_seconds"
    t.index ["effort_id", "lap", "split_id", "sub_split_bitkey"], name: "index_split_times_on_effort_id_and_time_point", unique: true
    t.index ["effort_id"], name: "index_split_times_on_effort_id"
    t.index ["lap", "split_id", "sub_split_bitkey"], name: "index_split_times_on_time_point"
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
    t.string "base_name", null: false
    t.integer "sub_split_bitmap", default: 1
    t.decimal "latitude", precision: 9, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.float "elevation"
    t.string "slug", null: false
    t.string "parameterized_base_name", null: false
    t.index ["base_name", "course_id"], name: "index_splits_on_base_name_and_course_id", unique: true
    t.index ["course_id"], name: "index_splits_on_course_id"
    t.index ["location_id"], name: "index_splits_on_location_id"
    t.index ["parameterized_base_name", "course_id"], name: "index_splits_on_parameterized_base_name_and_course_id", unique: true
    t.index ["parameterized_base_name"], name: "index_splits_on_parameterized_base_name"
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "protocol", default: 0, null: false
    t.string "resource_key"
    t.string "subscribable_type"
    t.bigint "subscribable_id"
    t.index ["resource_key"], name: "index_subscriptions_on_resource_key"
    t.index ["subscribable_type", "subscribable_id"], name: "index_subscriptions_on_subscribable_type_and_subscribable_id"
    t.index ["user_id", "subscribable_type", "subscribable_id", "protocol"], name: "index_subscriptions_on_unique_fields", unique: true
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

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.json "object"
    t.datetime "created_at"
    t.json "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "aid_stations", "events"
  add_foreign_key "aid_stations", "splits"
  add_foreign_key "courses", "organizations"
  add_foreign_key "efforts", "events"
  add_foreign_key "efforts", "people"
  add_foreign_key "event_groups", "organizations"
  add_foreign_key "event_series", "organizations"
  add_foreign_key "event_series", "results_templates"
  add_foreign_key "event_series_events", "event_series"
  add_foreign_key "event_series_events", "events"
  add_foreign_key "events", "courses"
  add_foreign_key "events", "event_groups"
  add_foreign_key "notifications", "efforts"
  add_foreign_key "people", "users"
  add_foreign_key "raw_times", "event_groups"
  add_foreign_key "raw_times", "split_times"
  add_foreign_key "results_categories", "organizations"
  add_foreign_key "results_template_categories", "results_categories"
  add_foreign_key "results_template_categories", "results_templates"
  add_foreign_key "results_templates", "organizations"
  add_foreign_key "split_times", "efforts"
  add_foreign_key "split_times", "splits"
  add_foreign_key "splits", "courses"
  add_foreign_key "splits", "locations"
  add_foreign_key "stewardships", "organizations"
  add_foreign_key "stewardships", "users"
  add_foreign_key "subscriptions", "users"

  create_view "best_effort_segments", sql_definition: <<-SQL
      WITH completed_lap_subquery AS (
           SELECT DISTINCT ON (split_times.effort_id) split_times.effort_id,
                  CASE
                      WHEN (splits.kind = 1) THEN split_times.lap
                      ELSE (split_times.lap - 1)
                  END AS completed_laps
             FROM (split_times
               JOIN splits ON ((splits.id = split_times.split_id)))
            ORDER BY split_times.effort_id, split_times.lap DESC, splits.distance_from_start DESC, split_times.sub_split_bitkey DESC
          )
   SELECT es.effort_id,
      e.first_name,
      e.last_name,
      e.bib_number,
      e.city,
      e.state_code,
      e.country_code,
      e.age,
      e.gender,
      e.slug,
      es.begin_split_id,
      es.begin_bitkey,
      es.begin_split_kind,
      es.end_split_id,
      es.end_bitkey,
      es.end_split_kind,
      es.lap,
      es.begin_time,
      es.elapsed_seconds,
      eg.home_time_zone,
      (ev.laps_required <> 1) AS multiple_laps,
      (cls.completed_laps >= ev.laps_required) AS finished
     FROM ((((efforts e
       JOIN effort_segments es ON ((es.effort_id = e.id)))
       JOIN events ev ON ((ev.id = e.event_id)))
       JOIN event_groups eg ON ((eg.id = ev.event_group_id)))
       JOIN completed_lap_subquery cls ON ((cls.effort_id = e.id)));
  SQL
end
