class CombineEventGroupSplitAttributes

  # The event_group should be loaded with includes(events: :splits)
  def self.perform(event_group)
    new(event_group).perform
  end

  def initialize(event_group)
    @event_group = event_group
    validate_compatible_splits
  end

  def perform
    ordered_split_names.map { |split_name| combined_attributes(split_name) }
  end

  private

  attr_reader :event_group

  def ordered_split_names
    @ordered_split_names ||= events.map { |event| event.ordered_splits.map(&:base_name) }.reduce(:|)
  end

  def combined_attributes(split_name)
    {'title' => split_name, 'entries' => sub_split_entries(split_name)}
  end

  def sub_split_entries(split_name)
    splits_by_event = splits_by_event(split_name)
    split = splits_by_event.values.first
    split.bitkeys.map do |bitkey|
      {'event_split_ids' => splits_by_event.transform_values(&:id),
       'sub_split_kind' => SubSplit.kind(bitkey).downcase,
       'label' => split.name(bitkey)}
    end
  end

  def splits_by_event(split_name)
    events.map { |event| [event.id, event_splits_by_name[event.id][split_name]] }.to_h.compact
  end

  def event_splits_by_name
    @event_splits_by_name ||= events.map { |event| [event.id, event.ordered_splits.index_by(&:base_name)] }.to_h
  end

  def events
    # This sort ensures ordered_split_names produces the expected result
    @events ||= event_group.events.sort_by { |event| -event.splits.size }
  end

  def validate_compatible_splits
    ordered_split_names.each do |split_name|
      if incompatible_sub_splits?(split_name)
        raise ArgumentError, "Splits with matching names must have matching sub_splits. The sub_splits for #{split_name} are incompatible."
      end
    end
  end

  def incompatible_sub_splits?(split_name)
    splits_by_event(split_name).values.map(&:sub_split_bitmap).uniq.many?
  end
end
