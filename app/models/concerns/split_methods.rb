module SplitMethods
  extend ActiveSupport::Concern

  def ordered_splits
    splits.ordered
  end

  def sub_splits
    ordered_splits.map(&:sub_splits).flatten
  end

  def ordered_splits_without_start
    ordered_splits.where(kind: [1, 2])
  end

  def ordered_splits_without_finish
    ordered_splits.where(kind: [0, 2])
  end

  def ordered_split_ids
    ordered_splits.ids
  end

  def start_split
    ordered_splits.start.first
  end

  def finish_split
    ordered_splits.finish.first
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
    splits_count < 3
  end

  def splits_count
    @splits_count ||= splits.size
  end

  def lap_splits_through(lap)
    cycled_lap_splits.first(lap * ordered_splits.size)
  end

  def cycled_lap_splits # For events with unlimited laps, call #cycled_lap_splits.first(n)
    ordered_splits.each_with_iteration { |split, i| LapSplit.new(i, split) }
  end

  def time_points_through(lap)
    cycled_time_points.first(lap * sub_splits.size)
  end

  def cycled_time_points # For events with unlimited laps, call #cycled_time_points.first(n)
    sub_splits.each_with_iteration { |sub_split, i| TimePoint.new(i, sub_split.split_id, sub_split.bitkey) }
  end
end
