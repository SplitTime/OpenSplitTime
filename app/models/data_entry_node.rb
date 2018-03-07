class DataEntryNode
  DISTANCE_THRESHOLD = 100 # Distance (in meters) below which split locations are deemed equivalent

  include DistanceMeasurable

  attr_reader :split_name, :sub_split_kind, :label, :latitude, :longitude, :event_split_ids, :event_aid_station_ids

  def initialize(args)
    ArgsValidator.validate(params: args, exclusive: [:split_name, :sub_split_kind, :label, :latitude, :longitude, :event_split_ids, :event_aid_station_ids])
    @split_name = args[:split_name]
    @sub_split_kind = args[:sub_split_kind]
    @label = args[:label]
    @latitude = args[:latitude]
    @longitude = args[:longitude]
    @event_split_ids = args[:event_split_ids]
    @event_aid_station_ids = args[:event_aid_station_ids]
  end
end
