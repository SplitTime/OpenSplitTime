# frozen_string_literal: true

class EventGroupSplitAnalyzer
  def initialize(event_group)
    @event_group = event_group
  end

  def splits_by_event(split_name)
    events.map { |event| [event.id, event_splits_by_name[event.id][split_name]] }.to_h.compact
  end

  def aid_stations_by_event(split_name)
    splits_by_event(split_name).transform_values { |split| aid_stations_by_split_id[split.id] }
  end

  def incompatible_locations
    ordered_split_names.select do |split_name|
      splits_by_event(split_name).values.select { |split| split.latitude && split.longitude }
          .combination(2).any? { |split_1, split_2| split_1.different_location?(split_2) }
    end
  end

  def ordered_split_names
    @ordered_split_names ||= events.map { |event| event.ordered_splits.map(&:parameterized_base_name) }.reduce(:|) || []
  end

  private

  attr_reader :event_group

  def events
    # This sort ensures ordered_split_names produces the expected result
    @events ||= event_group.events.sort_by { |event| -event.splits.size }
  end

  def event_splits_by_name
    @event_splits_by_name ||= events.map { |event| [event.id, event.ordered_splits.index_by(&:parameterized_base_name)] }.to_h
  end

  def aid_stations_by_split_id
    @aid_stations_by_split_id ||= events.flat_map(&:aid_stations).index_by(&:split_id)
  end
end
