class ComputeDataEntryNodes
  def self.perform(event_group)
    new(event_group).perform
  end

  def initialize(event_group)
    @event_group = event_group
  end

  def perform
    incompatible_locations.present? ? [] : ordered_split_names.map { |split_name| nodes_for(split_name) }.flatten
  end

  private

  attr_reader :event_group

  def splits_by_event(split_name)
    events.map { |event| [event.id, event_splits_by_name[event.id][split_name]] }.to_h.compact
  end

  def aid_stations_by_event(split_name)
    splits_by_event(split_name).transform_values { |split| aid_stations_by_split_id[split.id] }
  end

  def ordered_split_names
    @ordered_split_names ||= events.map { |event| event.ordered_splits.map(&:base_name) }.reduce(:|)
  end

  def nodes_for(split_name)
    splits = splits_by_event(split_name).values
    latitudes = splits.map(&:latitude).compact
    longitudes = splits.map(&:longitude).compact
    neediest_split = splits.max_by { |split| split.bitkeys.size }
    neediest_split.bitkeys.map do |bitkey|
      DataEntryNode.new(split_name.parameterize,
                        SubSplit.kind(bitkey).downcase,
                        neediest_split.name(bitkey),
                        latitudes.presence && (latitudes.sum / latitudes.size.to_f),
                        longitudes.presence && (longitudes.sum / longitudes.size.to_f),
                        splits_by_event(split_name).transform_values(&:id),
                        aid_stations_by_event(split_name).transform_values(&:id))
    end
  end

  def event_splits_by_name
    @event_splits_by_name ||= events.map { |event| [event.id, event.ordered_splits.index_by(&:base_name)] }.to_h
  end

  def aid_stations_by_split_id
    @aid_stations_by_split_id ||= events.map(&:aid_stations).flatten.index_by(&:split_id)
  end

  def incompatible_locations
    ordered_split_names.select do |split_name|
      splits_by_event(split_name).values.select { |split| split.latitude && split.longitude }
          .combination(2).any? { |split_1, split_2| split_1.different_location?(split_2) }
    end
  end

  def events
    # This sort ensures ordered_split_names produces the expected result
    @events ||= event_group.events.sort_by { |event| -event.splits.size }
  end
end
