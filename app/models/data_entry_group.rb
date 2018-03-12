# frozen_string_literal: true

DataEntryGroup = Struct.new(:data_entry_nodes) do

  def min_distance_from_start
    data_entry_nodes.map(&:min_distance_from_start).compact.min
  end

  def title
    data_entry_nodes.map { |node| node.split_name.split('-').join(' ').titleize }.uniq.join('/')
  end
end
