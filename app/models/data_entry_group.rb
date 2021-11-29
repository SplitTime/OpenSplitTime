# frozen_string_literal: true

DataEntryGroup = Struct.new(:data_entry_nodes) do

  def min_distance_from_start
    data_entry_nodes.map(&:min_distance_from_start).compact.min
  end

  def split_names
    data_entry_nodes.map(&:split_name)
  end

  def title
    split_names.map(&:parameterize).uniq.many? ? split_names.join('/') : split_names.first
  end
end
