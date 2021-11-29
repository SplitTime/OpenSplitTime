# frozen_string_literal: true

class CombineEventGroupSplitAttributes

  # The event_group should be loaded with includes(events: :splits)
  def self.perform(event_group, options = {})
    new(event_group, options).perform
  end

  def initialize(event_group, options = {})
    ArgsValidator.validate(subject: event_group,
                           params: options,
                           required: [:pair_by_location, :node_attributes],
                           exclusive: [:pair_by_location, :node_attributes],
                           class: self.class)
    @event_group = event_group
    @pair_by_location = options[:pair_by_location]
    @node_attributes = options[:node_attributes]
    @data_entry_groups = ComputeDataEntryGroups.perform(event_group, pair_by_location: pair_by_location)
  end

  def perform
    data_entry_groups.map { |deg| {title: deg.title, entries: entries_from_nodes(deg.data_entry_nodes)}.with_indifferent_access }
  end

  private

  attr_reader :event_group, :pair_by_location, :node_attributes, :data_entry_groups

  def entries_from_nodes(data_entry_nodes)
    data_entry_nodes.map do |node|
      node.to_h.slice(*node_attributes)
    end
  end
end
