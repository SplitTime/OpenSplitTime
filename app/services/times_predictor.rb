class TimesPredictor

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required_alternatives: [:effort, [:ordered_splits, :working_split_time]],
                           exclusive: [:effort, :ordered_splits, :working_split_time,
                                       :calc_model, :similar_effort_ids, :times_container],
                           class: self.class)
    @effort = args[:effort]
    @ordered_splits = args[:ordered_splits] || effort.ordered_splits.to_a
    @working_split_time = args[:working_split_time] || effort.valid_split_times.last || mock_start_split_time
    @calc_model = args[:calc_model] || :terrain
    @similar_effort_ids = args[:similar_effort_ids]
    @times_container = args[:times_container] ||
        SegmentTimesContainer.new(calc_model: calc_model, effort_ids: similar_effort_ids)
    validate_setup
  end

  def times_from_start
    @times_from_start ||= baseline_times.transform_values { |seconds| seconds * pace_factor + working_time }
  end

  def time_from_start(sub_split)
    baseline_time(sub_split) * pace_factor + working_time
  end

  def segment_time(segment)
    times_container.segment_time(segment) && times_container.segment_time(segment) * pace_factor
  end

  def limits(segment)
    times_container.limits(segment).transform_values { |limit| limit * pace_factor }
  end

  def data_status(segment, seconds)
    DataStatus.determine(limits(segment), seconds)
  end

  private

  attr_reader :effort, :ordered_splits, :working_split_time, :calc_model, :similar_effort_ids, :times_container

  def mock_start_split_time
    SplitTime.new(sub_split: start_split.sub_split_in, time_from_start: 0)
  end

  def baseline_times
    @baseline_times ||= segments.map { |segment| [segment.end_sub_split, times_container.segment_time(segment)] }.to_h
  end

  def segments
    @segments ||= SegmentsBuilder.segments(ordered_splits: ordered_splits, working_sub_split: working_sub_split)
  end

  def baseline_time(sub_split)
    times_container.segment_time(subject_segment(sub_split))
  end

  def subject_segment(sub_split)
    Segment.new(begin_sub_split: working_sub_split,
                end_sub_split: sub_split,
                begin_split: working_split,
                end_split: ordered_splits.find { |split| split.id == sub_split.split_id },
                order_control: false)
  end

  def pace_factor
    @pace_factor ||= measurable_pace? ? working_time / baseline_working_time : 1
  end

  def measurable_pace?
    working_split.distance_from_start > 0
  end

  def working_time
    working_split_time.time_from_start
  end

  def baseline_working_time
    times_container.segment_time(working_segment)
  end

  def working_segment
    Segment.new(begin_sub_split: start_split.sub_split_in,
                end_sub_split: working_sub_split,
                begin_split: start_split,
                end_split: working_split)
  end

  def start_split
    @start_split ||= ordered_splits.first
  end

  def working_sub_split
    @working_sub_split ||= working_split_time.sub_split
  end

  def working_split
    @working_split ||= ordered_splits.find { |split| split.id == working_split_time.split_id }
  end

  def validate_setup
    raise ArgumentError, 'working_split_time is not associated with the splits' unless working_split
  end
end