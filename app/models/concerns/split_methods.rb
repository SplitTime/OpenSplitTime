module SplitMethods
  extend ActiveSupport::Concern

  def ordered_splits
    splits.ordered
  end

  def ordered_splits_without_start
    ordered_splits.where(kind: [1, 2])
  end

  def ordered_splits_without_finish
    ordered_splits.where(kind: [0, 2])
  end

  def ordered_split_ids
    ordered_splits.map(&:id)
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

  def next_bitkey_hash(bitkey_hash)
    bitkey_hashes = sub_split_bitkey_hashes
    return nil if bitkey_hash == bitkey_hashes.last
    bitkey_hashes[bitkey_hashes.index(bitkey_hash) + 1]
  end

end
