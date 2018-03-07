class CombineEventGroupSplitAttributes

  # The event_group should be loaded with includes(events: :splits)
  def self.perform(event_group)
    new(event_group).perform
  end

  def initialize(event_group)
    @event_group = event_group
    @data_entry_groups = ComputeDataEntryGroups.perform(event_group)
  end

  def perform
    data_entry_groups.map { |deg| {title: deg.title, entries: entries_from_nodes(deg.data_entry_nodes)}.with_indifferent_access }
  end

  private

  attr_reader :event_group, :data_entry_groups

  def entries_from_nodes(data_entry_nodes)
    data_entry_nodes.map { |node| node.to_h.slice(:event_split_ids, :sub_split_kind, :label) }
  end
end
