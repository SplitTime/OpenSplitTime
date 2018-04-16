# frozen_string_literal: true

class RawTimePairer
  def self.pair(args)
    new(args).pair
  end

  def initialize(args)
    @event_group = args[:event_group]
    @raw_times = args[:raw_times]
    @pairer = args[:pairer] || ObjectPairer
    validate_setup
  end

  def pair
    raw_time_pairs.reject(&:blank?).flatten(1)
  end

  private

  attr_reader :event_group, :raw_times, :pairer

  def raw_time_pairs
    @raw_time_pairs ||= split_pairs.map { |split_pair| pairer.pair(objects: raw_times,
                                                                   identical_attributes: :bib_number,
                                                                   pairing_criteria: split_pair) }
  end

  def split_pairs
    @split_pairs ||= data_entry_groups.map { |deg| deg.data_entry_nodes.first(2).map { |node| split_name_and_bitkey(node) } }
  end

  def split_name_and_bitkey(node)
    {parameterized_split_name: node.split_name, bitkey: SubSplit.bitkey(node.sub_split_kind)}
  end

  def split_names
    @split_names ||= data_entry_groups.flat_map(&:split_names).to_set
  end

  def data_entry_groups
    @data_entry_groups ||= ComputeDataEntryGroups.perform(event_group, pair_by_location: false)
  end

  def validate_setup
    raise ArgumentError, 'All raw_times must match the provided event_group' unless raw_times.all? { |rt| rt.event_group_id == event_group.id }
    raise ArgumentError, 'All raw_times must match the split_names available in data_entry_groups' unless raw_times.all? { |rt| split_names.include?(rt.split_name) }
  end
end
