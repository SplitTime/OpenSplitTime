# frozen_string_literal: true

class DataEntryNode
  DISTANCE_THRESHOLD = 100 # Distance (in meters) below which split locations are deemed equivalent
  NODE_ATTRIBUTES = [:split_name, :sub_split_kind, :label, :latitude, :longitude,
                     :min_distance_from_start, :event_split_ids, :event_aid_station_ids].freeze

  include Locatable

  attr_reader *NODE_ATTRIBUTES

  def initialize(args)
    ArgsValidator.validate(params: args, exclusive: NODE_ATTRIBUTES)
    NODE_ATTRIBUTES.each { |attribute| instance_variable_set("@#{attribute}", args[attribute])}
  end

  def to_h
    NODE_ATTRIBUTES.map { |attribute| [attribute, send(attribute)] }.to_h
  end
end
