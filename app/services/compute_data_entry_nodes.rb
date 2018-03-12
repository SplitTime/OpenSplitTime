# frozen_string_literal: true

class ComputeDataEntryNodes
  def self.perform(event_group)
    new(event_group).perform
  end

  def initialize(event_group)
    @event_group = event_group
    @analyzer = EventGroupSplitAnalyzer.new(event_group)
  end

  def perform
    incompatible_locations.present? ? [] : ordered_split_names.flat_map { |split_name| nodes_for(split_name) }
  end

  private

  attr_reader :event_group, :analyzer
  delegate :incompatible_locations, :ordered_split_names, :splits_by_event, :aid_stations_by_event, to: :analyzer

  def nodes_for(split_name)
    splits = splits_by_event(split_name).values
    latitudes = splits.map(&:latitude).compact
    longitudes = splits.map(&:longitude).compact
    neediest_split = splits.max_by { |split| split.bitkeys.size }
    neediest_split.bitkeys.map do |bitkey|
      DataEntryNode.new(split_name: split_name,
                        sub_split_kind: SubSplit.kind(bitkey).downcase,
                        label: neediest_split.name(bitkey),
                        latitude: latitudes.presence && (latitudes.sum / latitudes.size.to_f),
                        longitude: longitudes.presence && (longitudes.sum / longitudes.size.to_f),
                        min_distance_from_start: splits.map(&:distance_from_start).min,
                        event_split_ids: splits_by_event(split_name).transform_values(&:id),
                        event_aid_station_ids: aid_stations_by_event(split_name).transform_values(&:id))
    end
  end
end
