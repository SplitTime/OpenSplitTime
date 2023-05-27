class RawTimeResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :split_name
  attribute :bitkey
  attribute :bib_number
  attribute :absolute_time
  attribute :entered_time
  attribute :with_pacer
  attribute :stopped_here
  attribute :source
  attribute :reviewed_by
  attribute :reviewed_at
  attribute :created_by
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :parameterized_split_name
  attribute :remarks
  attribute :sortable_bib_number
  attribute :data_status
  attribute :matchable_bib_number
  attribute :disassociated_from_effort
  attribute :entered_lap
  attribute :lap, index: false
  attribute :split_time_exists, index: false

  # Associations
  attribute :versions
  attribute :event_group
  attribute :split_time

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
