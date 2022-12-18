class SplitResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :location_id
  attribute :distance_from_start
  attribute :vert_gain_from_start
  attribute :vert_loss_from_start
  attribute :kind
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :created_by
  attribute :updated_by
  attribute :description
  attribute :base_name
  attribute :sub_split_bitmap
  attribute :latitude
  attribute :longitude
  attribute :elevation
  attribute :slug
  attribute :parameterized_base_name

  # Associations
  attribute :slugs
  attribute :versions
  attribute :course
  attribute :split_times
  attribute :aid_stations
  attribute :events

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
