# frozen_string_literal: true

class MatchEventGroupSplitName
  def self.perform(event_group, split_name, validate: true)
    new(event_group, split_name, validate: validate).perform
  end

  def initialize(event_group, split_name, validate: true)
    @event_group = event_group
    @split_name = split_name
    validate_compatible_splits if validate
  end

  def perform
    {event_splits: splits_by_event, event_aid_stations: aid_stations_by_event}
  end

  def incompatible_sub_splits?
    splits_by_event.values.map(&:sub_split_bitmap).uniq.many?
  end

  def incompatible_locations?
    splits_by_event.values.select { |split| split.latitude && split.longitude }.combination(2).any? do |split_1, split_2|
      split_1.distance_from(split_2) > 100
    end
  end

  private

  attr_reader :event_group, :split_name
  delegate :events, to: :event_group

  def splits_by_event
    @splits_by_event ||= events.map { |event| [event.id, event_splits_by_name[event.id][split_name]] }.to_h.compact
  end

  def aid_stations_by_event
    splits_by_event.transform_values { |split| aid_stations_by_split_id[split.id] }
  end

  def event_splits_by_name
    events.map { |event| [event.id, event.ordered_splits.index_by(&:base_name)] }.to_h
  end

  def aid_stations_by_split_id
    @aid_stations_by_split_id ||= events.flat_map(&:aid_stations).index_by(&:split_id)
  end

  def validate_compatible_splits
    if incompatible_sub_splits?
      raise ArgumentError, "Splits with matching names must have matching sub_splits. The sub_splits for #{split_name} are incompatible. "
    end
    if incompatible_locations?
      raise ArgumentError, "Splits with matching names must be in the same location. The locations for #{split_name} are incompatible. "
    end
  end
end
