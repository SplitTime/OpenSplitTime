class SplitResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :distance_from_start, index: true
  attribute :vert_gain_from_start
  attribute :vert_loss_from_start
  attribute :kind, index: true
  attribute :created_at, form: false
  attribute :updated_at, form: false
  attribute :description
  attribute :base_name, index: true
  attribute :sub_split_bitmap, index: true
  attribute :latitude
  attribute :longitude
  attribute :elevation
  attribute :slug
  attribute :parameterized_base_name

  # Associations
  attribute :slugs
  attribute :versions
  attribute :course, index: true
  attribute :split_times
  attribute :aid_stations
  attribute :events

  def self.display_name(record)
    record.base_name
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
