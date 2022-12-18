class EventGroupResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :available_live
  attribute :concealed
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :created_by
  attribute :updated_by
  attribute :slug
  attribute :data_entry_grouping_strategy
  attribute :monitor_pacers
  attribute :home_time_zone
  attribute :entrant_photos, index: false

  # Associations
  attribute :partners
  attribute :slugs
  attribute :versions
  attribute :events
  attribute :efforts
  attribute :raw_times
  attribute :organization

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
