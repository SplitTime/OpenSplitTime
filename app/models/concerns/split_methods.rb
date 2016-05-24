module SplitMethods
  extend ActiveSupport::Concern

  module ClassMethods

    def splits_from_ids(split_ids)
      splits_by_id = Split.find(split_ids).index_by(&:id)
      split_ids.collect { |id| splits_by_id[id] }
    end

  end

  def waypoint_groups
    result = []
    array = splits.ordered.pluck_to_hash(:id, :distance_from_start)
    array.group_by { |e| e[:distance_from_start] }.each do |_,v|
      result << v.map { |row| row[:id] }
    end
    result
  end

  def waypoint_groups_without_start
    result = waypoint_groups
    result.shift
    result
  end

  def waypoint_group(split)
    splits.at_same_distance(split)
  end

  def base_splits
    splits.base
  end

  def base_split_names
    result = []
    base_splits.each do |split|
      result << split.base_name
    end
    result
  end

  def out_splits
    Course.splits_from_ids(waypoint_groups[0..-2].map { |group| group[-1] }) # Excludes the finish split
  end

  def in_splits
    Course.splits_from_ids(waypoint_groups_without_start.map { |group| group[0] }) # Excludes the start split
  end

  def ordered_splits
    splits.ordered
  end

  def ordered_splits_without_start
    splits.intermediate.union(splits.finish).ordered
  end

  def ordered_split_ids
    splits.ordered.map(&:id)
  end

  def start_split
    splits.start.first
  end

  def finish_split
    splits.finish.first
  end

  def next_split(split)
    return nil if split.finish?
    splits = ordered_splits
    splits[splits.index(split) + 1]
  end

  def previous_split(split)
    return nil if split.start?
    splits = ordered_splits
    splits[splits.index(split) - 1]
  end

  def simple?
    splits.count < 3
  end

end
