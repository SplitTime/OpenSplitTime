class StatTimesCalculator

  def initialize(args)
    ArgsValidator.validate(params: args, required: :effort)
    @effort = args[:effort]
    @ordered_splits = args[:ordered_splits] || effort.event.ordered_splits
    @valid_split_times = args[:valid_split_times] || effort.split_times.valid_status.to_a
    @effort_finder = args[:effort_finder] ||
        SimilarEffortFinder.new(sub_split: completed_sub_split, time_from_start: completed_time,
                                split: completed_split, finished: true)
    @segment_times_container = args[:segment_times_container] ||
        SegmentTimesContainer.new(efforts: effort_finder.efforts)
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

  attr_accessor :effort, :ordered_splits, :valid_split_times, :effort_finder, :segment_times_container

  def segments
    @segments ||= SegmentsBuilder.segments(ordered_splits: ordered_splits)
  end

  def stat_times
    segments.map { |segment| [segment.end_sub_split, segment_times_container[segment].mean] }
  end

  def completed_time
    completed_split_time.time_from_start
  end

  def completed_split
    ordered_splits.find { |split| split.id == completed_sub_split.split_id }
  end

  def completed_sub_split
    completed_split_time.sub_split
  end

  def completed_split_time
    @completed_split_time ||= ordered_sub_splits.map { |sub_split| indexed_split_times[sub_split] }.compact.last
  end

  def ordered_sub_splits
    @ordered_sub_splits ||= ordered_splits.map(&:sub_splits).flatten
  end

  def indexed_split_times
    @indexed_split_times ||= valid_split_times.index_by(&:sub_split)
  end

  def validate_setup
    raise ArgumentError, 'One or more provided splits_times is not associated with the effort' unless
        valid_split_times.map(&:effort_id).uniq == [effort.id]
    raise ArgumentError, 'One or more provided splits_times is not associated with the splits' unless
        (valid_split_times.map(&:split_id).uniq - ordered_splits.map(&:id)).empty?
  end
end