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
    incompatible_locations.present? ?
        [incompatible_notice_node] :
        parameterized_split_names.flat_map { |split_name| nodes_for(split_name) }
  end

  private

  attr_reader :event_group, :analyzer
  delegate :incompatible_locations, :parameterized_split_names, :splits_by_event, :aid_stations_by_event, to: :analyzer

  def nodes_for(split_name)
    splits = splits_by_event(split_name).values
    latitudes = splits.map(&:latitude).compact
    longitudes = splits.map(&:longitude).compact
    neediest_split = splits.max_by { |split| split.bitkeys.size }
    neediest_split.bitkeys.map do |bitkey|
      DataEntryNode.new(split_name: neediest_split.base_name,
                        display_split_name: neediest_split.base_name,
                        parameterized_split_name: neediest_split.parameterized_base_name,
                        sub_split_kind: SubSplit.kind(bitkey).downcase,
                        label: neediest_split.name(bitkey),
                        latitude: latitudes.presence && latitudes.average,
                        longitude: longitudes.presence && longitudes.average,
                        min_distance_from_start: splits.map(&:distance_from_start).min,
                        event_split_ids: splits_by_event(split_name).transform_values(&:id),
                        event_aid_station_ids: aid_stations_by_event(split_name).transform_values(&:id))
    end
  end

  def incompatible_notice_node
    DataEntryNode.new(split_name: "Incompatible: #{incompatible_locations.map(&:titleize).to_sentence}",
                      display_split_name: "Incompatible: #{incompatible_locations.to_sentence}",
                      parameterized_split_name: 'incompatible-locations-present',
                      sub_split_kind: 'in',
                      label: "Incompatible: #{incompatible_locations.to_sentence}",
                      latitude: nil,
                      longitude: nil,
                      min_distance_from_start: 0,
                      event_split_ids: {},
                      event_aid_station_ids: {})
  end
end
