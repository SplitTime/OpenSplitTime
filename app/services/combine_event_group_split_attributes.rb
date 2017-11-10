class CombineEventGroupSplitAttributes

  # The event_group should be loaded with includes(events: :splits)
  def self.perform(event_group)
    new(event_group).perform
  end

  def initialize(event_group)
    @event_group = event_group
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
    splits_by_event = MatchEventGroupSplitName.perform(event_group, split_name)[:event_splits]
    split = splits_by_event.values.first
    split.bitkeys.map do |bitkey|
      {'event_split_ids' => splits_by_event.transform_values(&:id),
       'sub_split_kind' => SubSplit.kind(bitkey).downcase,
       'label' => split.name(bitkey)}
    end
  end

  def events
    # This sort ensures ordered_split_names produces the expected result
    @events ||= event_group.events.sort_by { |event| -event.splits.size }
  end
end
