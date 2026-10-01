class EventGroupResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :available_live, index: true
  attribute :concealed, index: true
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :created_by
  attribute :slug, index: true
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
  attribute :organization, index: true

  def self.display_name(record)
    record.name
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
