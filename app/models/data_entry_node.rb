class DataEntryNode
  include Locatable

  # Distance (in meters) below which split locations are deemed equivalent
  DISTANCE_THRESHOLD = Split::DISTANCE_THRESHOLD
  NODE_ATTRIBUTES = [:split_name, :parameterized_split_name, :sub_split_kind, :label,
                     :latitude, :longitude, :min_distance_from_start].freeze

  attr_reader(*NODE_ATTRIBUTES)

  def initialize(split_name: nil, parameterized_split_name: nil, sub_split_kind: nil,
                 label: nil, latitude: nil, longitude: nil, min_distance_from_start: nil)
    @split_name = split_name
    @parameterized_split_name = parameterized_split_name
    @sub_split_kind = sub_split_kind
    @label = label
    @latitude = latitude
    @longitude = longitude
    @min_distance_from_start = min_distance_from_start
  end

  def to_h
    NODE_ATTRIBUTES.index_with { |attribute| send(attribute) }
  end
end
