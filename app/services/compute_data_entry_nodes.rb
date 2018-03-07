class ComputeDataEntryNodes
  SPLIT_DISTANCE_THRESHOLD = 100

  def self.perform(event_group)
    new(event_group).perform
  end

  def initialize(event_group)
    @event_group = event_group
  end

  def perform
    incompatible_locations? ? [] : ordered_split_names.map { |split_name| nodes_for(split_name) }.flatten
  end

  private

  attr_reader :event_group, :split_name
  delegate :events, to: :event_group

  def splits_by_event(split_name)
    events.map { |event| [event.id, event_splits_by_name[event.id][split_name]] }.to_h.compact
  end

  def ordered_split_names
    @ordered_split_names ||= events.map { |event| event.ordered_splits.map(&:base_name) }.reduce(:|)
  end

  def nodes_for(split_name)
    splits = events.map { |event| event_splits_by_name[event.id][split_name] }.compact
    latitudes = splits.map(&:latitude).compact
    longitudes = splits.map(&:longitude).compact
    neediest_split = splits.max_by { |split| split.bitkeys.size }
    neediest_split.bitkeys.map do |bitkey|
      DataEntryNode.new(split_name.parameterize,
                        SubSplit.kind(bitkey).downcase,
                        neediest_split.name(bitkey),
                        latitudes.presence && (latitudes.sum / latitudes.size.to_f),
                        longitudes.presence && (longitudes.sum / longitudes.size.to_f))
    end
  end

  def event_splits_by_name
    events.map { |event| [event.id, event.ordered_splits.index_by(&:base_name)] }.to_h
  end

  def incompatible_locations?
    ordered_split_names.any? do |split_name|
      splits_by_event(split_name).values.select { |split| split.latitude && split.longitude }.combination(2).any? do |split_1, split_2|
        split_1.distance_from(split_2) > SPLIT_DISTANCE_THRESHOLD
      end
    end
  end

  def events
    # This sort ensures ordered_split_names produces the expected result
    @events ||= event_group.events.sort_by { |event| -event.splits.size }
  end
end
