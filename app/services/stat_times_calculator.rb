class StatTimesCalculator

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: :ordered_splits,
                           required_alternatives: [:segment_times_container, :efforts],
                           exclusive: [:ordered_splits, :segment_times_container, :efforts])
    @ordered_splits = args[:ordered_splits]
    @segment_times_container = args[:segment_times_container] || SegmentTimesContainer.new(efforts: args[:efforts])
  end

  def times_from_start
    @times_from_start ||= stat_times.to_h
  end

  def segment_time(segment)
    unless ordered_splits.include?(segment.begin_split) && ordered_splits.include?(segment.end_split)
      raise ArgumentError, "segment #{segment.name} is not valid for #{self}"
    end
    segment_times_container.estimated_time(segment)
  end

  def limits(segment)
    segment_times_container.limits(segment)
  end

  private

  attr_accessor :effort, :ordered_splits, :segment_times_container

  def segments
    @segments ||= SegmentsBuilder.segments(ordered_splits: ordered_splits)
  end

  def stat_times
    segments.map { |segment| [segment.end_sub_split, segment_times_container[segment].estimated_time] }
  end
end