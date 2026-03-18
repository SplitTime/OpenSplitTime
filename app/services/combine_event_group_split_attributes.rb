class CombineEventGroupSplitAttributes
  # The event_group should be loaded with includes(events: :splits)
  def self.perform(event_group, pair_by_location:, node_attributes:)
    new(event_group, pair_by_location: pair_by_location, node_attributes: node_attributes).perform
  end

  def initialize(event_group, pair_by_location:, node_attributes:)
    @event_group = event_group
    @pair_by_location = pair_by_location
    @node_attributes = node_attributes
    validate_setup
  end

  def perform
    data_entry_groups.map do |deg|
      { title: deg.title, entries: entries_from_nodes(deg.data_entry_nodes) }.with_indifferent_access
    end
  end

  private

  attr_reader :event_group, :pair_by_location, :node_attributes

  def data_entry_groups
    ComputeDataEntryGroups.perform(event_group, pair_by_location: pair_by_location)
  end

  def entries_from_nodes(data_entry_nodes)
    data_entry_nodes.map do |node|
      node.to_h.slice(*node_attributes)
    end
  end

  def validate_setup
    raise ArgumentError, "combine_event_group_split_attributes must include event_group" if event_group.nil?
    raise ArgumentError, "combine_event_group_split_attributes must include pair_by_location" if pair_by_location.nil?
    raise ArgumentError, "combine_event_group_split_attributes must include node_attributes" if node_attributes.nil?
  end
end
