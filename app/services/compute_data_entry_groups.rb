class ComputeDataEntryGroups
  def self.perform(event_group, options = {})
    new(event_group, options).perform
  end

  def initialize(event_group, options = {})
    @event_group = event_group
    @data_entry_nodes = ComputeDataEntryNodes.perform(event_group)
    @pairer = options[:pairer] || ObjectPairer
  end

  def perform
    node_groups.map { |node_group| DataEntryGroup.new(node_group) }.sort_by(&:min_distance_from_start)
  end

  private

  attr_reader :event_group, :data_entry_nodes, :pairer

  def node_groups
    unpaired_nodes, paired_nodes = sub_split_matched_nodes.partition(&:one?)
    distance_matched_nodes = pairer.pair(objects: unpaired_nodes.flatten, identical_attributes: :location, pairing_criteria: [{}, {}])
    paired_nodes + distance_matched_nodes.map(&:compact)
  end

  def sub_split_matched_nodes
    pairer.pair(objects: data_entry_nodes,
                identical_attributes: :split_name,
                pairing_criteria: [{sub_split_kind: 'in'}, {sub_split_kind: 'out'}])
        .map(&:compact)
  end
end
