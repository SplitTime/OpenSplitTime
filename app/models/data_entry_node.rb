class DataEntryNode
  DISTANCE_THRESHOLD = 100 # Distance (in meters) below which split locations are deemed equivalent
  NODE_ATTRIBUTES = [:split_name, :sub_split_kind, :label, :latitude, :longitude,
                     :min_distance_from_start, :event_split_ids, :event_aid_station_ids]

  include Locatable

  attr_reader *NODE_ATTRIBUTES

  def initialize(args)
    ArgsValidator.validate(params: args, exclusive: NODE_ATTRIBUTES)
    @split_name = args[:split_name]
    @sub_split_kind = args[:sub_split_kind]
    @label = args[:label]
    @latitude = args[:latitude]
    @longitude = args[:longitude]
    @min_distance_from_start = args[:min_distance_from_start]
    @event_split_ids = args[:event_split_ids]
    @event_aid_station_ids = args[:event_aid_station_ids]
  end

  def to_h
    NODE_ATTRIBUTES.map { |attribute| [attribute, send(attribute)] }.to_h
  end
end
