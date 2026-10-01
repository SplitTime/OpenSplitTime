class EffortResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :wave
  attribute :bib_number, index: true
  attribute :city
  attribute :state_code
  attribute :age
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :first_name, index: true
  attribute :last_name, index: true
  attribute :gender, index: true
  attribute :country_code
  attribute :birthdate
  attribute :data_status, index: true
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
  attribute :event, index: true
  attribute :person, index: true
  attribute :split_times
  attribute :notifications

  def self.display_name(record)
    record.full_name
  end

  # Uncomment this to customize the default sort column and direction.
  # def self.default_sort_column
  #   "created_at"
  # end
  #
  # def self.default_sort_direction
  #   "desc"
  # end
end
