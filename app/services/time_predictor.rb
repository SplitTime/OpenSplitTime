class TimePredictor

  def self.segment_time(args)
    new(args).segment_time
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: :segment,
                           required_alternatives: [:effort, [:ordered_splits, :completed_split_time]],
                           exclusive: [:effort, :ordered_splits, :completed_split_time,
                                       :calc_model, :similar_effort_ids, :times_container],
                           class: self.class)
    @segment = args[:segment]
    @effort = args[:effort]
    @ordered_splits = args[:ordered_splits] || effort.ordered_splits.to_a
    @completed_split_time = args[:completed_split_time] || effort.valid_split_times.last || mock_start_split_time
    @calc_model = args[:calc_model] || :terrain
    @similar_effort_ids = args[:similar_effort_ids]
    @times_container = args[:times_container] ||
        SegmentTimesContainer.new(calc_model: calc_model, effort_ids: similar_effort_ids)
    validate_setup
  end

  def segment_time
    times_container.segment_time(segment) && times_container.segment_time(segment) * pace_factor
  end

  def limits
    times_container.limits(segment).transform_values { |limit| limit * pace_factor }
  end

  def data_status(seconds)
    DataStatus.determine(limits, seconds)
  end

  private

  attr_reader :segment, :effort, :ordered_splits, :completed_split_time,
              :calc_model, :similar_effort_ids, :times_container

  def pace_factor
    @pace_factor ||= measurable_pace? ? actual_completed_time / typical_completed_time : 1
  end

  def measurable_pace?
    completed_split.distance_from_start > 0
  end

  def actual_completed_time
    completed_split_time.time_from_start
  end

  def typical_completed_time
    times_container.segment_time(completed_segment)
  end

  def completed_segment
    Segment.new(begin_sub_split: start_split.sub_split_in, end_sub_split: completed_sub_split,
                begin_split: start_split, end_split: completed_split)
  end

  def start_split
    @start_split ||= ordered_splits.first
  end

  def completed_sub_split
    @completed_sub_split ||= completed_split_time.sub_split
  end

  def completed_split
    @completed_split ||= ordered_splits.find { |split| split.id == completed_split_time.split_id }
  end

  def mock_start_split_time
    SplitTime.new(sub_split: start_split.sub_split_in, time_from_start: 0)
  end

  def validate_setup
    raise ArgumentError, 'completed_split_time is not associated with the splits' unless completed_split
  end
end