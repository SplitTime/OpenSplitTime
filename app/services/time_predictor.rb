class TimePredictor

  def initialize(args)
    ParamValidator.validate(params: args, required: [:effort, :sub_split], class: self.class)
    @effort = args[:effort]
    @sub_split = args[:sub_split]
    @ordered_splits = args[:ordered_splits] || effort.event.ordered_splits.to_a
    @valid_split_times = args[:valid_split_times] || effort.split_times.valid_status.to_a
    @effort_segment_times = args[:effort_segment_times] || EffortSegmentTimes.new(efforts: similar_efforts)
    validate_setup
  end

  def predicted_time
    (sub_split == ordered_sub_splits.first) ? 0 : seconds_from_start
  end

  private

  attr_reader :effort, :sub_split, :ordered_splits, :effort_segment_times, :valid_split_times

  def similar_efforts
    @similar_efforts ||=
        SimilarEffortFinder.new(sub_split: completed_sub_split, time_from_start: completed_time, finished: true).efforts
  end

  def seconds_from_start
    completed_time + (effort_segment_times[subject_segment].estimated_time * pace_factor)
  end

  def pace_factor
    pace_baseline.zero? ? 1 : completed_time / pace_baseline
  end

  def pace_baseline
    effort_segment_times[completed_segment].estimated_time
  end

  def subject_average_time
    effort_segment_times[subject_segment].mean
  end

  def completed_segment
    Segment.new(ordered_sub_splits.first,
                completed_sub_split,
                indexed_splits[ordered_sub_splits.first.split_id],
                indexed_splits[completed_sub_split.split_id])
  end

  def subject_segment
    Segment.new(completed_sub_split,
                sub_split,
                indexed_splits[completed_sub_split.split_id],
                indexed_splits[sub_split.split_id])
  end

  def completed_time
    completed_split_time.time_from_start
  end

  def completed_sub_split
    completed_split_time.sub_split
  end

  def completed_split_time
    @completed_split_time ||= relevant_sub_splits.map { |sub_split| indexed_split_times[sub_split] }.compact.last
  end

  def relevant_sub_splits
    @relevant_sub_splits ||= ordered_sub_splits[0..ordered_sub_splits.index(sub_split) - 1]
  end

  def indexed_splits
    @indexed_splits ||= ordered_splits.index_by(&:id)
  end

  def ordered_sub_splits
    @ordered_sub_splits ||= ordered_splits.map(&:sub_splits).flatten
  end

  def indexed_split_times
    @indexed_split_times ||= valid_split_times.index_by(&:sub_split)
  end

  def validate_setup
    raise RuntimeError, 'Effort has not started' unless indexed_split_times[ordered_sub_splits.first].present?
  end
end