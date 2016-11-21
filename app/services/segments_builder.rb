class SegmentsBuilder

  def self.segments(args)
    new(args).segments
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required_alternatives: [:sub_splits, :ordered_splits],
                           exclusive: [:sub_splits, :ordered_splits])
    @ordered_splits = args[:ordered_splits] || Split.where(id: args[:sub_splits].map(&:split_id)).ordered.to_a
    @sub_splits = args[:sub_splits] || sub_splits_from_splits
    validate_setup
  end

  def segments
    @segments ||=
        sub_splits.map { |sub_split| Segment.new(start_sub_split, sub_split, start_split, indexed_splits[sub_split.split_id]) }
  end

  private

  attr_accessor :sub_splits, :ordered_splits

  def sub_splits_from_splits
    @sub_splits_from_splits ||= ordered_splits.map(&:sub_splits).flatten
  end

  def indexed_splits
    @indexed_splits ||= ordered_splits.index_by(&:id)
  end

  def start_split
    @start_split ||= ordered_splits.first
  end

  def start_sub_split
    @start_sub_split ||= sub_splits.first
  end

  def validate_setup
    raise ArgumentError, 'sub_splits and ordered_splits do not reconcile' unless sub_splits_from_splits == sub_splits
  end
end