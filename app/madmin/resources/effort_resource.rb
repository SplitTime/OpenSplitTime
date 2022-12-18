class EffortResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :wave
  attribute :bib_number
  attribute :city
  attribute :state_code
  attribute :age
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :created_by
  attribute :updated_by
  attribute :first_name
  attribute :last_name
  attribute :gender
  attribute :country_code
  attribute :birthdate
  attribute :data_status
  attribute :beacon_url
  attribute :report_url
  attribute :phone
  attribute :email
  attribute :slug
  attribute :checked_in
  attribute :emergency_contact
  attribute :emergency_phone
  attribute :scheduled_start_time
  attribute :topic_resource_key
  attribute :comments
  attribute :state_name
  attribute :country_name
  attribute :overall_performance
  attribute :stopped_split_time_id
  attribute :final_split_time_id
  attribute :started
  attribute :beyond_start
  attribute :stopped
  attribute :dropped
  attribute :finished
  attribute :synced_at
  attribute :completed_laps
  attribute :photo, index: false

  # Associations
  attribute :subscriptions
  attribute :followers
  attribute :slugs
  attribute :versions
  attribute :event
  attribute :person
  attribute :split_times
  attribute :notifications

  # Uncomment this to customize the display name of records in the admin area.
  # def self.display_name(record)
  #   record.name
  # end

  # Uncomment this to customize the default sort column and direction.
  # def self.default_sort_column
  #   "created_at"
  # end
  #
  # def self.default_sort_direction
  #   "desc"
  # end
end
