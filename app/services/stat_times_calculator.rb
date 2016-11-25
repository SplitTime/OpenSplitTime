class StatTimesCalculator

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required_alternatives: [:effort, [:ordered_splits, :working_split_time]],
                           exclusive: [:effort, :ordered_splits, :working_split_time,
                                       :segment_times_container, :similar_efforts])
    @effort = args[:effort]
    @ordered_splits = args[:ordered_splits] || effort.ordered_splits.to_a
    @working_split_time = args[:working_split_time] || effort.valid_split_times.last
    @segment_times_container = args[:segment_times_container] ||
        SegmentTimesContainer.new(efforts: args[:similar_efforts] || found_efforts)
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

  attr_accessor :effort, :ordered_splits, :working_split_time, :segment_times_container

  def found_efforts
    SimilarEffortFinder.new(sub_split: working_sub_split, time_from_start: working_time,
                            split: working_split, finished: true).efforts
  end

  def segments
    @segments ||= SegmentsBuilder.segments(ordered_splits: ordered_splits)
  end

  def stat_times
    segments.map { |segment| [segment.end_sub_split, segment_times_container[segment].estimated_time * normalizing_factor] }
  end

  def normalizing_factor
    working_time / segment_times_container[working_segment].mean
  end

  def working_segment
    segments.find { |segment| segment.end_sub_split == working_sub_split }
  end

  def working_time
    working_split_time.time_from_start
  end

  def working_split
    ordered_splits.find { |split| split.sub_splits.include?(working_sub_split) }
  end

  def working_sub_split
    working_split_time.sub_split
  end

  def validate_setup
    raise ArgumentError, 'working_split_time is not associated with the splits' unless
        ordered_splits.map(&:sub_splits).flatten.include?(working_split_time.sub_split)
  end
end