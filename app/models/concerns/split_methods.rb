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
end
