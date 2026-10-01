class RawTimeResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :split_name, index: true
  attribute :bitkey, index: true
  attribute :bib_number, index: true
  attribute :absolute_time, index: true
  attribute :entered_time
  attribute :with_pacer
  attribute :stopped_here
  attribute :source, index: true
  attribute :reviewer
  attribute :reviewed_at
  attribute :creator
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :parameterized_split_name
  attribute :remarks
  attribute :sortable_bib_number
  attribute :data_status, index: true
  attribute :matchable_bib_number
  attribute :disassociated_from_effort
  attribute :entered_lap
  attribute :lap, index: false
  attribute :split_time_exists, index: false

  # Associations
  attribute :versions
  attribute :event_group, index: true
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
