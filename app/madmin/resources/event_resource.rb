class EventResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :historical_name
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :created_by
  attribute :scheduled_start_time
  attribute :beacon_url
  attribute :laps_required
  attribute :slug
  attribute :short_name
  attribute :efforts_count, form: false
  attribute :notice_text
  attribute :topic_resource_key

  # Associations
  attribute :slugs
  attribute :versions
  attribute :course
  attribute :event_group
  attribute :results_template
  attribute :event_series_events
  attribute :event_series
  attribute :efforts
  attribute :aid_stations
  attribute :splits
  attribute :partners

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
