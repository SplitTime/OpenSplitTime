class StatTimesCalculator

  def initialize(args)
    ArgsValidator.validate(params: args, required_alternatives: [:effort, :ordered_splits])
    @effort = args[:effort]
    @ordered_splits = args[:ordered_splits] || effort.ordered_splits.to_a
    @completed_split_time = args[:completed_split_time] || effort.valid_split_times.last
    @similar_efforts = args[:similar_efforts] ||
        SimilarEffortFinder.new(sub_split: completed_sub_split, time_from_start: completed_time,
                                split: completed_split, finished: true).efforts
    @segment_times_container = args[:segment_times_container] ||
        SegmentTimesContainer.new(efforts: similar_efforts)
    validate_setup
  end

  def times_from_start
    @times_from_start ||= stat_times.to_h
  end

  def segment_time(segment)
    unless times_from_start[segment.end_sub_split] && times_from_start[segment.begin_sub_split]
      raise ArgumentError, "segment #{segment.name} is not valid for #{self}"
    end
    times_from_start[segment.end_sub_split] - times_from_start[segment.begin_sub_split]
  end

  private

  attr_accessor :effort, :ordered_splits, :completed_split_time, :similar_efforts, :segment_times_container

  def segments
    @segments ||= SegmentsBuilder.segments(ordered_splits: ordered_splits)
  end

  def stat_times
    segments.map { |segment| [segment.end_sub_split, segment_times_container[segment].mean * normalizing_factor] }
  end

  def normalizing_factor
    completed_time / segment_times_container[completed_segment].mean
  end

  def completed_segment
    segments.find { |segment| segment.end_sub_split == completed_sub_split }
  end

  def completed_time
    completed_split_time.time_from_start
  end

  def completed_split
    ordered_splits.find { |split| split.sub_splits.include?(completed_sub_split) }
  end

  def completed_sub_split
    completed_split_time.sub_split
  end

  def validate_setup
    raise ArgumentError, 'completed_split_time is not associated with the splits' unless
        ordered_splits.map(&:sub_splits).flatten.include?(completed_split_time.sub_split)
  end
end