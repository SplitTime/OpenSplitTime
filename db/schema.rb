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

ActiveRecord::Schema[7.0].define(version: 2024_12_20_002632) do
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
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "aid_stations", id: :serial, force: :cascade do |t|
    t.integer "event_id"
    t.integer "split_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["event_id"], name: "index_aid_stations_on_event_id"
    t.index ["split_id"], name: "index_aid_stations_on_split_id"
  end

  create_table "analytics_file_downloads", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.string "name", null: false
    t.string "filename", null: false
    t.string "byte_size", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id"], name: "index_file_downloads_on_record"
    t.index ["user_id"], name: "index_analytics_file_downloads_on_user_id"
  end

  create_table "connections", force: :cascade do |t|
    t.string "service_identifier", null: false
    t.string "source_type", null: false
    t.string "source_id", null: false
    t.string "destination_type", null: false
    t.bigint "destination_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_type", "destination_id"], name: "index_connections_on_destination"
    t.index ["service_identifier", "source_type", "source_id", "destination_type", "destination_id"], name: "index_connections_on_service_source_and_destination", unique: true
  end

  create_table "course_group_courses", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.bigint "course_group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_group_id"], name: "index_course_group_courses_on_course_group_id"
    t.index ["course_id"], name: "index_course_group_courses_on_course_id"
  end

  create_table "course_groups", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_course_groups_on_organization_id"
  end

  create_table "courses", id: :serial, force: :cascade do |t|
    t.string "name", limit: 64, null: false
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "created_by"
    t.datetime "next_start_time", precision: nil
    t.string "slug", null: false
    t.bigint "organization_id"
    t.boolean "concealed"
    t.json "track_points"
    t.index ["organization_id"], name: "index_courses_on_organization_id"
    t.index ["slug"], name: "index_courses_on_slug", unique: true
  end

  create_table "credentials", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "service_identifier", null: false
    t.string "key", null: false
    t.string "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_credentials_on_user_id"
  end

  create_table "data_migrations", primary_key: "version", id: :string, force: :cascade do |t|
  end

  create_table "effort_segments", id: false, force: :cascade do |t|
    t.integer "course_id"
    t.integer "begin_split_id"
    t.integer "begin_bitkey"
    t.integer "end_split_id"
    t.integer "end_bitkey"
    t.integer "effort_id"
    t.integer "lap"
    t.datetime "begin_time", precision: nil
    t.datetime "end_time", precision: nil
    t.integer "elapsed_seconds"
    t.integer "begin_split_kind"
    t.integer "end_split_kind"
    t.index ["begin_split_id", "begin_bitkey", "end_split_id", "end_bitkey", "effort_id", "lap"], name: "index_effort_segments_on_unique_attributes", unique: true
    t.index ["begin_split_id", "begin_bitkey", "end_split_id", "end_bitkey"], name: "index_effort_segments_on_sub_splits"
    t.index ["course_id", "begin_split_kind", "end_split_kind"], name: "index_effort_segments_by_course_id_and_split_kind"
    t.index ["course_id"], name: "index_effort_segments_on_course_id"
    t.index ["effort_id"], name: "index_effort_segments_on_effort_id"
    t.index ["elapsed_seconds"], name: "index_effort_segments_on_elapsed_seconds"
  end

  create_table "efforts", id: :serial, force: :cascade do |t|
    t.integer "event_id", null: false
    t.integer "person_id"
    t.string "wave"
    t.integer "bib_number"
    t.string "city", limit: 64
    t.string "state_code", limit: 64
    t.integer "age"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "created_by"
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
    t.datetime "scheduled_start_time", precision: nil
    t.string "topic_resource_key"
    t.string "comments"
    t.string "state_name"
    t.string "country_name"
    t.bit "overall_performance", limit: 96
    t.integer "stopped_split_time_id"
    t.integer "final_split_time_id"
    t.boolean "started"
    t.boolean "beyond_start"
    t.boolean "stopped"
    t.boolean "dropped"
    t.boolean "finished"
    t.datetime "synced_at"
    t.integer "completed_laps"
    t.boolean "bib_number_hardcoded"
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "created_by"
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "scoring_method"
    t.index ["organization_id"], name: "index_event_series_on_organization_id"
    t.index ["results_template_id"], name: "index_event_series_on_results_template_id"
  end

  create_table "event_series_events", force: :cascade do |t|
    t.bigint "event_id"
    t.bigint "event_series_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["event_id"], name: "index_event_series_events_on_event_id"
    t.index ["event_series_id"], name: "index_event_series_events_on_event_series_id"
  end

  create_table "events", id: :serial, force: :cascade do |t|
    t.integer "course_id", null: false
    t.string "historical_name", limit: 64
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "created_by"
    t.datetime "scheduled_start_time", precision: nil
    t.string "beacon_url"
    t.integer "laps_required"
    t.string "slug", null: false
    t.integer "event_group_id"
    t.string "short_name"
    t.bigint "results_template_id", null: false
    t.integer "efforts_count", default: 0
    t.string "notice_text"
    t.string "topic_resource_key"
    t.index ["course_id"], name: "index_events_on_course_id"
    t.index ["event_group_id", "short_name"], name: "index_events_on_event_group_id_and_short_name", unique: true
    t.index ["event_group_id"], name: "index_events_on_event_group_id"
    t.index ["results_template_id"], name: "index_events_on_results_template_id"
    t.index ["slug"], name: "index_events_on_slug", unique: true
  end

  create_table "export_jobs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "status"
    t.string "source_url"
    t.datetime "started_at"
    t.integer "elapsed_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "controller_name"
    t.string "resource_class_name"
    t.string "sql_string"
    t.string "error_message"
    t.index ["user_id"], name: "index_export_jobs_on_user_id"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at", precision: nil
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "historical_facts", force: :cascade do |t|
    t.bigint "person_id"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.date "birthdate"
    t.integer "gender", null: false
    t.string "address"
    t.string "city"
    t.string "state_code"
    t.string "country_code"
    t.string "state_name"
    t.string "country_name"
    t.string "email"
    t.string "phone"
    t.integer "kind", null: false
    t.integer "quantity"
    t.string "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.bigint "organization_id", null: false
    t.string "personal_info_hash"
    t.integer "year"
    t.string "external_id"
    t.index ["last_name", "first_name", "state_code"], name: "index_historical_facts_on_names_and_state_code"
    t.index ["organization_id", "person_id", "kind"], name: "index_historical_facts_uniq_kind", where: "(kind = 3)"
    t.index ["organization_id", "person_id", "year", "kind"], name: "index_historical_facts_uniq_kind_year", where: "(kind = ANY (ARRAY[0, 1, 2, 7, 8, 9, 10, 11]))"
    t.index ["organization_id", "personal_info_hash", "person_id"], name: "index_hf_on_organization_and_hash_and_person"
    t.index ["organization_id", "personal_info_hash"], name: "index_hf_on_organization_and_hash"
    t.index ["organization_id"], name: "index_historical_facts_on_organization_id"
    t.index ["person_id"], name: "index_historical_facts_on_person_id"
    t.index ["personal_info_hash"], name: "index_historical_facts_on_personal_info_hash"
  end

  create_table "import_jobs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "parent_type", null: false
    t.bigint "parent_id", null: false
    t.string "format", null: false
    t.integer "status"
    t.string "error_message"
    t.integer "row_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "succeeded_count"
    t.integer "failed_count"
    t.datetime "started_at", precision: nil
    t.integer "elapsed_time"
    t.integer "ignored_count"
    t.index ["parent_type", "parent_id"], name: "index_import_jobs_on_parent"
    t.index ["user_id"], name: "index_import_jobs_on_user_id"
  end

  create_table "locations", id: :serial, force: :cascade do |t|
    t.string "name", limit: 64, null: false
    t.text "description"
    t.float "elevation"
    t.decimal "latitude", precision: 9, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "created_by"
    t.integer "updated_by"
  end

  create_table "lotteries", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name"
    t.date "scheduled_start_date"
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "concealed"
    t.integer "status"
    t.string "calculation_class"
    t.integer "service_form_download_count", default: 0
    t.index ["organization_id"], name: "index_lotteries_on_organization_id"
  end

  create_table "lotteries_entrant_service_details", primary_key: "lottery_entrant_id", force: :cascade do |t|
    t.datetime "form_accepted_at"
    t.datetime "form_rejected_at"
    t.string "form_accepted_comments"
    t.string "form_rejected_comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "completed_date"
  end

  create_table "lottery_divisions", force: :cascade do |t|
    t.bigint "lottery_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "maximum_entries", null: false
    t.integer "maximum_wait_list"
    t.index ["lottery_id"], name: "index_lottery_divisions_on_lottery_id"
  end

  create_table "lottery_draws", force: :cascade do |t|
    t.bigint "lottery_id", null: false
    t.bigint "lottery_ticket_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.index ["lottery_id"], name: "index_lottery_draws_on_lottery_id"
    t.index ["lottery_ticket_id"], name: "index_lottery_draws_on_lottery_ticket_id", unique: true
  end

  create_table "lottery_entrants", force: :cascade do |t|
    t.bigint "lottery_division_id", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.integer "gender", null: false
    t.integer "number_of_tickets", null: false
    t.string "birthdate"
    t.string "city"
    t.string "state_code"
    t.string "country_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state_name"
    t.string "country_name"
    t.boolean "pre_selected", default: false
    t.string "external_id"
    t.boolean "withdrawn"
    t.date "service_completed_date"
    t.bigint "person_id"
    t.string "email"
    t.string "phone"
    t.index ["lottery_division_id", "first_name", "last_name", "birthdate"], name: "index_lottery_index_on_unique_key_attributes", unique: true
    t.index ["lottery_division_id"], name: "index_lottery_entrants_on_lottery_division_id"
    t.index ["person_id"], name: "index_lottery_entrants_on_person_id"
  end

  create_table "lottery_simulation_runs", force: :cascade do |t|
    t.bigint "lottery_id", null: false
    t.string "name"
    t.jsonb "context"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "requested_count"
    t.integer "status"
    t.string "error_message"
    t.integer "success_count"
    t.integer "failure_count"
    t.datetime "started_at", precision: nil
    t.integer "elapsed_time"
    t.index ["lottery_id"], name: "index_lottery_simulation_runs_on_lottery_id"
  end

  create_table "lottery_simulations", force: :cascade do |t|
    t.bigint "lottery_simulation_run_id", null: false
    t.integer "ticket_ids", default: [], array: true
    t.jsonb "results"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lottery_simulation_run_id"], name: "index_lottery_simulations_on_lottery_simulation_run_id"
  end

  create_table "lottery_tickets", force: :cascade do |t|
    t.bigint "lottery_entrant_id", null: false
    t.bigint "lottery_id", null: false
    t.integer "reference_number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lottery_entrant_id"], name: "index_lottery_tickets_on_lottery_entrant_id"
    t.index ["lottery_id", "reference_number"], name: "index_lottery_tickets_on_lottery_id_and_reference_number", unique: true
    t.index ["lottery_id"], name: "index_lottery_tickets_on_lottery_id"
    t.index ["reference_number"], name: "index_lottery_tickets_on_reference_number"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "effort_id", null: false
    t.integer "distance", null: false
    t.integer "bitkey", null: false
    t.integer "follower_ids", default: [], array: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "created_by"
    t.integer "kind"
    t.string "topic_resource_key"
    t.string "subject"
    t.text "notice_text"
    t.index ["effort_id"], name: "index_notifications_on_effort_id"
  end

  create_table "organizations", id: :serial, force: :cascade do |t|
    t.string "name", limit: 64, null: false
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "created_by"
    t.boolean "concealed", default: true
    t.string "slug", null: false
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "partners", id: :serial, force: :cascade do |t|
    t.string "banner_link"
    t.integer "weight", default: 1, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name", null: false
    t.string "partnerable_type"
    t.integer "partnerable_id"
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "created_by"
    t.string "country_code", limit: 2
    t.integer "user_id"
    t.boolean "concealed", default: false
    t.string "slug", null: false
    t.string "topic_resource_key"
    t.string "state_name"
    t.string "country_name"
    t.index ["slug"], name: "index_people_on_slug", unique: true
    t.index ["topic_resource_key"], name: "index_people_on_topic_resource_key", unique: true
    t.index ["user_id"], name: "index_people_on_user_id", unique: true
  end

  create_table "projection_assessment_runs", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.integer "completed_lap", null: false
    t.integer "completed_split_id", null: false
    t.integer "completed_bitkey", null: false
    t.integer "projected_lap", null: false
    t.integer "projected_split_id", null: false
    t.integer "projected_bitkey", null: false
    t.integer "status"
    t.string "error_message"
    t.integer "success_count"
    t.integer "failure_count"
    t.datetime "started_at"
    t.integer "elapsed_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_projection_assessment_runs_on_event_id"
  end

  create_table "projection_assessments", force: :cascade do |t|
    t.bigint "projection_assessment_run_id", null: false
    t.bigint "effort_id", null: false
    t.datetime "projected_early"
    t.datetime "projected_best"
    t.datetime "projected_late"
    t.datetime "actual"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["effort_id"], name: "index_projection_assessments_on_effort_id"
    t.index ["projection_assessment_run_id"], name: "index_projection_assessments_on_projection_assessment_run_id"
  end

  create_table "raw_times", force: :cascade do |t|
    t.bigint "event_group_id", null: false
    t.bigint "split_time_id"
    t.string "split_name", null: false
    t.integer "bitkey", null: false
    t.string "bib_number", null: false
    t.datetime "absolute_time", precision: nil
    t.string "entered_time"
    t.boolean "with_pacer", default: false
    t.boolean "stopped_here", default: false
    t.string "source", null: false
    t.integer "reviewed_by"
    t.datetime "reviewed_at", precision: nil
    t.integer "created_by"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "nonbinary", default: false
    t.string "slug"
    t.index ["organization_id"], name: "index_results_categories_on_organization_id"
  end

  create_table "results_template_categories", force: :cascade do |t|
    t.bigint "results_template_id"
    t.bigint "results_category_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "position"
    t.boolean "fixed_position"
    t.index ["results_category_id"], name: "index_results_template_categories_on_results_category_id"
    t.index ["results_template_id"], name: "index_results_template_categories_on_results_template_id"
  end

  create_table "results_templates", force: :cascade do |t|
    t.bigint "organization_id"
    t.string "name"
    t.integer "aggregation_method"
    t.integer "podium_size"
    t.integer "point_system", default: [], array: true
    t.string "slug", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["organization_id"], name: "index_results_templates_on_organization_id"
  end

  create_table "sendgrid_events", force: :cascade do |t|
    t.string "email"
    t.datetime "timestamp"
    t.string "smtp_id"
    t.string "event"
    t.string "category"
    t.string "sg_event_id"
    t.string "sg_message_id"
    t.string "reason"
    t.string "status"
    t.string "ip"
    t.string "response"
    t.string "event_type"
    t.string "useragent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shortened_urls", id: :serial, force: :cascade do |t|
    t.integer "owner_id"
    t.string "owner_type", limit: 20
    t.text "url", null: false
    t.string "unique_key", limit: 10, null: false
    t.string "category"
    t.integer "use_count", default: 0, null: false
    t.datetime "expires_at", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["category"], name: "index_shortened_urls_on_category"
    t.index ["owner_id", "owner_type"], name: "index_shortened_urls_on_owner_id_and_owner_type"
    t.index ["unique_key"], name: "index_shortened_urls_on_unique_key", unique: true
    t.index ["url"], name: "index_shortened_urls_on_url"
  end

  create_table "split_times", id: :serial, force: :cascade do |t|
    t.integer "effort_id", null: false
    t.integer "split_id", null: false
    t.integer "data_status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "sub_split_bitkey", null: false
    t.boolean "pacer"
    t.string "remarks"
    t.integer "lap", null: false
    t.boolean "stopped_here", default: false
    t.datetime "absolute_time", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "created_by"
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "level", default: 0
    t.index ["organization_id"], name: "index_stewardships_on_organization_id"
    t.index ["user_id", "organization_id"], name: "index_stewardships_on_user_id_and_organization_id", unique: true
    t.index ["user_id"], name: "index_stewardships_on_user_id"
  end

  create_table "subscriptions", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "protocol", default: 0, null: false
    t.string "resource_key"
    t.string "subscribable_type"
    t.bigint "subscribable_id"
    t.string "endpoint"
    t.index ["resource_key"], name: "index_subscriptions_on_resource_key"
    t.index ["subscribable_type", "subscribable_id"], name: "index_subscriptions_on_subscribable_type_and_subscribable_id"
    t.index ["user_id", "subscribable_type", "subscribable_id", "protocol", "endpoint"], name: "index_subscriptions_on_unique_fields_with_endpoint", unique: true
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
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "pref_distance_unit", default: 0, null: false
    t.integer "pref_elevation_unit", default: 0, null: false
    t.string "slug", null: false
    t.string "phone"
    t.string "http_endpoint"
    t.string "https_endpoint"
    t.string "phone_confirmation_token"
    t.datetime "phone_confirmed_at", precision: nil
    t.datetime "phone_confirmation_sent_at", precision: nil
    t.datetime "exports_viewed_at"
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
    t.datetime "created_at", precision: nil
    t.json "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "aid_stations", "events"
  add_foreign_key "aid_stations", "splits"
  add_foreign_key "analytics_file_downloads", "users"
  add_foreign_key "course_group_courses", "course_groups"
  add_foreign_key "course_group_courses", "courses"
  add_foreign_key "course_groups", "organizations"
  add_foreign_key "courses", "organizations"
  add_foreign_key "credentials", "users"
  add_foreign_key "efforts", "events"
  add_foreign_key "efforts", "people"
  add_foreign_key "event_groups", "organizations"
  add_foreign_key "event_series", "organizations"
  add_foreign_key "event_series", "results_templates"
  add_foreign_key "event_series_events", "event_series"
  add_foreign_key "event_series_events", "events"
  add_foreign_key "events", "courses"
  add_foreign_key "events", "event_groups"
  add_foreign_key "export_jobs", "users"
  add_foreign_key "historical_facts", "organizations"
  add_foreign_key "historical_facts", "people"
  add_foreign_key "import_jobs", "users"
  add_foreign_key "lotteries", "organizations"
  add_foreign_key "lottery_divisions", "lotteries"
  add_foreign_key "lottery_draws", "lotteries"
  add_foreign_key "lottery_draws", "lottery_tickets"
  add_foreign_key "lottery_entrants", "lottery_divisions"
  add_foreign_key "lottery_entrants", "people"
  add_foreign_key "lottery_simulation_runs", "lotteries"
  add_foreign_key "lottery_simulations", "lottery_simulation_runs"
  add_foreign_key "lottery_tickets", "lotteries"
  add_foreign_key "lottery_tickets", "lottery_entrants"
  add_foreign_key "notifications", "efforts"
  add_foreign_key "people", "users"
  add_foreign_key "projection_assessment_runs", "events"
  add_foreign_key "projection_assessments", "efforts"
  add_foreign_key "projection_assessments", "projection_assessment_runs"
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
  create_function :pg_search_dmetaphone, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.pg_search_dmetaphone(text)
       RETURNS text
       LANGUAGE sql
       IMMUTABLE STRICT
      AS $function$
      SELECT array_to_string(ARRAY(SELECT dmetaphone(unnest(regexp_split_to_array($1, E' +')))), ' ')
      $function$
  SQL


  create_view "best_effort_segments", sql_definition: <<-SQL
      SELECT es.effort_id,
      e.event_id,
      e.first_name,
      e.last_name,
      e.bib_number,
      e.city,
      e.state_code,
      e.country_code,
      e.age,
      e.gender,
      e.slug,
      e.person_id,
      concat(e.gender, ':', ((e.age / 10) * 10)) AS age_group,
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
      es.course_id,
      (ev.laps_required <> 1) AS multiple_laps,
      (e.completed_laps >= ev.laps_required) AS finished,
      ((es.begin_split_kind = 0) AND (es.end_split_kind = 1)) AS full_course,
      c.name AS course_name
     FROM ((((efforts e
       JOIN effort_segments es ON ((es.effort_id = e.id)))
       JOIN events ev ON ((ev.id = e.event_id)))
       JOIN event_groups eg ON ((eg.id = ev.event_group_id)))
       JOIN courses c ON ((c.id = ev.course_id)));
  SQL
  create_view "lottery_division_ticket_stats", sql_definition: <<-SQL
      WITH entrant_list AS (
           SELECT DISTINCT ON (lottery_entrants.id) lottery_divisions.name AS division_name,
              lottery_entrants.lottery_division_id AS division_id,
              lottery_tickets.lottery_id,
              lottery_entrants.first_name,
              lottery_entrants.last_name,
              lottery_entrants.number_of_tickets,
              ((lottery_draws.id IS NOT NULL) AND (lottery_draws."position" <= lottery_divisions.maximum_entries)) AS accepted,
              ((lottery_draws.id IS NOT NULL) AND (lottery_draws."position" > lottery_divisions.maximum_entries)) AS waitlisted
             FROM (((lottery_entrants
               JOIN lottery_divisions ON ((lottery_divisions.id = lottery_entrants.lottery_division_id)))
               JOIN lottery_tickets ON ((lottery_tickets.lottery_entrant_id = lottery_entrants.id)))
               LEFT JOIN lottery_draws ON ((lottery_draws.lottery_ticket_id = lottery_tickets.id)))
            ORDER BY lottery_entrants.id, lottery_draws.id
          )
   SELECT lottery_id,
      division_id,
      division_name,
      number_of_tickets,
      count(*) FILTER (WHERE accepted) AS accepted_entrants_count,
      count(*) FILTER (WHERE waitlisted) AS waitlisted_entrants_count,
      count(*) AS entrants_count
     FROM entrant_list
    GROUP BY lottery_id, division_id, division_name, number_of_tickets
    ORDER BY lottery_id, division_id, division_name, number_of_tickets;
  SQL
  create_view "course_group_finishers", sql_definition: <<-SQL
      SELECT ((cg.id || ':'::text) || p.id) AS id,
      p.id AS person_id,
      p.first_name,
      p.last_name,
      p.gender,
      p.city,
      p.state_code,
      p.country_code,
      p.state_name,
      p.country_name,
      p.slug,
      cg.id AS course_group_id,
      count(e.id) AS finish_count
     FROM ((((((course_groups cg
       JOIN course_group_courses cgc ON ((cgc.course_group_id = cg.id)))
       JOIN courses c ON ((c.id = cgc.course_id)))
       JOIN events e ON ((e.course_id = c.id)))
       JOIN event_groups eg ON ((e.event_group_id = eg.id)))
       JOIN efforts ef ON ((ef.event_id = e.id)))
       JOIN people p ON ((ef.person_id = p.id)))
    WHERE ((ef.finished = true) AND (eg.concealed = false))
    GROUP BY cg.id, p.id;
  SQL
  create_view "lotteries_calculations_hardrock_2025s", sql_definition: <<-SQL
      WITH applicants AS (
           SELECT historical_facts.organization_id,
              historical_facts.person_id,
              any_value(historical_facts.external_id) AS external_id,
              any_value(historical_facts.gender) AS gender,
              COALESCE(bool_or(((event_groups.organization_id = historical_facts.organization_id) AND (efforts.finished OR (efforts.started AND (EXTRACT(year FROM events.scheduled_start_time) < (2021)::numeric))))), false) AS finisher
             FROM (((historical_facts
               LEFT JOIN efforts ON ((efforts.person_id = historical_facts.person_id)))
               LEFT JOIN events ON ((events.id = efforts.event_id)))
               LEFT JOIN event_groups ON ((event_groups.id = events.event_group_id)))
            WHERE ((historical_facts.kind = 11) AND (historical_facts.year = 2024))
            GROUP BY historical_facts.organization_id, historical_facts.person_id
          ), last_start_year AS (
           SELECT event_groups.organization_id,
              efforts.person_id,
              max(EXTRACT(year FROM events.scheduled_start_time)) AS year
             FROM ((efforts
               JOIN events ON ((events.id = efforts.event_id)))
               JOIN event_groups ON ((event_groups.id = events.event_group_id)))
            WHERE efforts.started
            GROUP BY event_groups.organization_id, efforts.person_id
            ORDER BY efforts.person_id
          ), dns_since_last_start_count AS (
           SELECT historical_facts.organization_id,
              historical_facts.person_id,
              count(*) AS dns_since_last_start_count
             FROM (historical_facts
               LEFT JOIN last_start_year USING (organization_id, person_id))
            WHERE ((historical_facts.kind = 0) AND (historical_facts.year < 2025) AND ((historical_facts.year)::numeric > COALESCE(last_start_year.year, (0)::numeric)))
            GROUP BY historical_facts.organization_id, historical_facts.person_id
          ), last_reset_year AS (
           SELECT event_groups.organization_id,
              efforts.person_id,
              max(EXTRACT(year FROM events.scheduled_start_time)) AS year
             FROM ((efforts
               JOIN events ON ((events.id = efforts.event_id)))
               JOIN event_groups ON ((event_groups.id = events.event_group_id)))
            WHERE (efforts.finished OR (efforts.started AND (EXTRACT(year FROM events.scheduled_start_time) > (2022)::numeric)))
            GROUP BY event_groups.organization_id, efforts.person_id
          ), dns_since_last_reset_count AS (
           SELECT historical_facts.organization_id,
              historical_facts.person_id,
              count(*) AS dns_since_last_reset_count
             FROM (historical_facts
               LEFT JOIN last_reset_year USING (organization_id, person_id))
            WHERE ((historical_facts.kind = 0) AND (historical_facts.year < 2025) AND ((historical_facts.year)::numeric > COALESCE(last_reset_year.year, (0)::numeric)))
            GROUP BY historical_facts.organization_id, historical_facts.person_id
          ), finish_year_count AS (
           SELECT event_groups.organization_id,
              efforts.person_id,
              count(*) AS finish_year_count
             FROM ((efforts
               JOIN events ON ((events.id = efforts.event_id)))
               JOIN event_groups ON ((event_groups.id = events.event_group_id)))
            WHERE (efforts.finished AND (EXTRACT(year FROM events.scheduled_start_time) < (2025)::numeric))
            GROUP BY event_groups.organization_id, efforts.person_id
          ), vmulti_year_count AS (
           SELECT historical_facts.organization_id,
              historical_facts.person_id,
              historical_facts.quantity AS vmulti_year_count
             FROM historical_facts
            WHERE (historical_facts.kind = 3)
          ), volunteer_year_count AS (
           SELECT historical_facts.organization_id,
              historical_facts.person_id,
              count(DISTINCT historical_facts.year) AS volunteer_year_count
             FROM historical_facts
            WHERE ((historical_facts.kind = ANY (ARRAY[1, 2])) AND (historical_facts.year < 2025))
            GROUP BY historical_facts.organization_id, historical_facts.person_id
          ), major_volunteer_year_count AS (
           SELECT historical_facts.organization_id,
              historical_facts.person_id,
              count(*) AS major_volunteer_year_count
             FROM historical_facts
            WHERE ((historical_facts.kind = 2) AND (historical_facts.year = 2024))
            GROUP BY historical_facts.organization_id, historical_facts.person_id
          ), all_counts AS (
           SELECT applicants.organization_id,
              applicants.person_id,
              applicants.external_id,
              applicants.finisher,
              applicants.gender,
              (
                  CASE
                      WHEN applicants.finisher THEN COALESCE(dns_since_last_start_count.dns_since_last_start_count, (0)::bigint)
                      ELSE COALESCE(dns_since_last_reset_count.dns_since_last_reset_count, (0)::bigint)
                  END)::integer AS dns_ticket_count,
              (COALESCE(finish_year_count.finish_year_count, (0)::bigint))::integer AS finish_ticket_count,
              (((COALESCE(volunteer_year_count.volunteer_year_count, (0)::bigint) + COALESCE(vmulti_year_count.vmulti_year_count, 0)) / 5))::integer AS volunteer_ticket_count,
              (COALESCE(major_volunteer_year_count.major_volunteer_year_count, (0)::bigint))::integer AS volunteer_major_ticket_count
             FROM ((((((applicants
               LEFT JOIN dns_since_last_start_count USING (organization_id, person_id))
               LEFT JOIN dns_since_last_reset_count USING (organization_id, person_id))
               LEFT JOIN finish_year_count USING (organization_id, person_id))
               LEFT JOIN vmulti_year_count USING (organization_id, person_id))
               LEFT JOIN volunteer_year_count USING (organization_id, person_id))
               LEFT JOIN major_volunteer_year_count USING (organization_id, person_id))
          )
   SELECT row_number() OVER () AS id,
      organization_id,
      person_id,
      external_id,
      gender,
      finisher,
          CASE
              WHEN ((gender = 0) AND finisher) THEN 'Male Finishers'::text
              WHEN (gender = 0) THEN 'Male Nevers'::text
              WHEN finisher THEN 'Female Finishers'::text
              ELSE 'Female Nevers'::text
          END AS division,
      dns_ticket_count,
      finish_ticket_count,
      volunteer_ticket_count,
      volunteer_major_ticket_count,
      (
          CASE
              WHEN finisher THEN (((((dns_ticket_count + finish_ticket_count) + volunteer_ticket_count) + volunteer_major_ticket_count) + 1))::double precision
              ELSE pow((2)::double precision, (((dns_ticket_count + volunteer_ticket_count) + volunteer_major_ticket_count))::double precision)
          END)::integer AS ticket_count
     FROM all_counts;
  SQL
  create_view "lotteries_division_rankings", sql_definition: <<-SQL
      WITH ranked_draws AS (
           SELECT lottery_tickets.lottery_entrant_id,
              rank() OVER division_window AS division_rank
             FROM ((lottery_tickets
               JOIN lottery_draws ON ((lottery_draws.lottery_ticket_id = lottery_tickets.id)))
               JOIN lottery_entrants lottery_entrants_1 ON ((lottery_entrants_1.id = lottery_tickets.lottery_entrant_id)))
            WINDOW division_window AS (PARTITION BY lottery_entrants_1.lottery_division_id ORDER BY
                  CASE
                      WHEN ((lottery_entrants_1.withdrawn IS FALSE) OR (lottery_entrants_1.withdrawn IS NULL)) THEN 0
                      WHEN (lottery_entrants_1.withdrawn IS TRUE) THEN 1
                      ELSE NULL::integer
                  END, lottery_draws.created_at)
          )
   SELECT lottery_entrants.id AS lottery_entrant_id,
      lottery_divisions.name AS division_name,
      ranked_draws.division_rank,
          CASE
              WHEN lottery_entrants.withdrawn THEN 4
              WHEN (ranked_draws.division_rank <= lottery_divisions.maximum_entries) THEN 0
              WHEN (ranked_draws.division_rank <= (lottery_divisions.maximum_entries + lottery_divisions.maximum_wait_list)) THEN 1
              WHEN (ranked_draws.division_rank IS NOT NULL) THEN 2
              ELSE 3
          END AS draw_status
     FROM ((lottery_entrants
       LEFT JOIN ranked_draws ON ((ranked_draws.lottery_entrant_id = lottery_entrants.id)))
       JOIN lottery_divisions ON ((lottery_entrants.lottery_division_id = lottery_divisions.id)));
  SQL
end
