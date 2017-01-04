class SegmentsBuilder

  def self.segments(args)
    new(args).segments
  end

  def self.segments_with_zero_start(args)
    new(args).segments_with_zero_start
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required_alternatives: [:ordered_splits, :sub_splits],
                           exclusive: [:ordered_splits, :sub_splits],
                           class: self.class)
    @ordered_splits = args[:ordered_splits] || Split.where(id: args[:sub_splits].map(&:split_id)).ordered.to_a
    @sub_splits = args[:sub_splits] || sub_splits_from_splits
    validate_setup
  end

  def segments
    sub_splits.each_cons(2).map { |begin_ss, end_ss| Segment.new(begin_sub_split: begin_ss,
                                                                 end_sub_split: end_ss,
                                                                 begin_split: indexed_splits[begin_ss.split_id],
                                                                 end_split: indexed_splits[end_ss.split_id]) }
  end

  def segments_with_zero_start
    segments.unshift(zero_start_segment)
  end

  private

  attr_accessor :sub_splits, :ordered_splits, :working_sub_split

  def sub_splits_from_splits
    ordered_splits.map(&:sub_splits).flatten
  end

  def indexed_splits
    @indexed_splits ||= ordered_splits.index_by(&:id)
  end

  def start_split
    @start_split ||= ordered_splits.first
  end

  def zero_start_segment
    Segment.new(begin_sub_split: start_split.sub_split_in,
                end_sub_split: start_split.sub_split_in,
                begin_split: start_split,
                end_split: start_split)
  end

  def validate_setup
    raise ArgumentError, 'sub_splits and ordered_splits do not reconcile' unless sub_splits_from_splits == sub_splits
  end
end