# frozen_string_literal: true

class DataEntryNode
  include Locatable

  DISTANCE_THRESHOLD = Split::DISTANCE_THRESHOLD # Distance (in meters) below which split locations are deemed equivalent
  NODE_ATTRIBUTES = [:split_name, :parameterized_split_name, :sub_split_kind, :label,
                     :latitude, :longitude, :min_distance_from_start].freeze

  attr_reader *NODE_ATTRIBUTES

  def initialize(args)
    ArgsValidator.validate(params: args, exclusive: NODE_ATTRIBUTES)
    NODE_ATTRIBUTES.each { |attribute| instance_variable_set("@#{attribute}", args[attribute])}
  end

  def to_h
    NODE_ATTRIBUTES.map { |attribute| [attribute, send(attribute)] }.to_h
  end
end
