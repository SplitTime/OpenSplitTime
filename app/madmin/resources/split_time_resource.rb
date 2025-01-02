class SplitTimeResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :data_status
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :sub_split_bitkey
  attribute :pacer
  attribute :remarks
  attribute :lap
  attribute :stopped_here
  attribute :absolute_time
  attribute :elapsed_seconds
  attribute :absolute_estimate_early, index: false
  attribute :absolute_estimate_late, index: false
  attribute :designated_seconds_from_start, index: false
  attribute :matching_raw_time_id, index: false
  attribute :effort_ids_ahead, index: false

  # Associations
  attribute :versions
  attribute :effort
  attribute :split
  attribute :raw_times

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
