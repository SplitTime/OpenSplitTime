class EventSeriesResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :slug
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :scoring_method

  # Associations
  attribute :slugs
  attribute :versions
  attribute :organization
  attribute :results_template
  attribute :event_series_events
  attribute :events
  attribute :efforts

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
