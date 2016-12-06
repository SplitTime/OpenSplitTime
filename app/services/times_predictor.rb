class TimesPredictor

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required_alternatives: [:effort, [:ordered_splits, :working_split_time]],
                           exclusive: [:effort, :ordered_splits, :working_split_time,
                                       :calc_model, :similar_effort_ids, :times_container],
                           class: self.class)
    @effort = args[:effort]
    @ordered_splits = args[:ordered_splits] || effort.ordered_splits.to_a
    @working_split_time = args[:working_split_time] || effort.valid_split_times.last
    @calc_model = args[:calc_model] || :terrain
    @similar_effort_ids = args[:similar_effort_ids]
    @times_container = args[:times_container] ||
        SegmentTimesContainer.new(calc_model: calc_model, effort_ids: similar_effort_ids)
    validate_setup
  end

  # Note: #times_from_start will return all times regardless of segment completion.
  # Call #segment_time when you need the most accurate times for a particular segment.
  # When using #times_from_start, consider finding similar_effort_ids using
  # SimilarEffortsFinder#effort_ids with args[:finished] = true

  def times_from_start
    @times_from_start ||= baseline_times.transform_values { |seconds| seconds * pace_factor }
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

  def pace_factor
    measurable_pace? ? working_time / baseline_working_time : 1
  end

  def measurable_pace?
    working_split_time && working_time > 0
  end

  def working_time
    working_split_time.time_from_start
  end

  def baseline_working_time
    times_container.segment_time(working_segment)
  end

  def working_segment
    Segment.new(start_split.sub_split_in, working_split_time.sub_split, start_split, working_split)
  end

  def start_split
    ordered_splits.first
  end

  def working_split
    ordered_splits.find { |split| split.id == working_split_time.split_id }
  end

  def baseline_times
    segments.map { |segment| [segment.end_sub_split, times_container.segment_time(segment)] }.to_h
  end

  def segments
    SegmentsBuilder.segments(ordered_splits: ordered_splits)
  end

  def validate_setup
    raise ArgumentError, 'working_split_time is not associated with the splits' if working_split_time &&
        ordered_splits.map(&:sub_splits).flatten.exclude?(working_split_time.sub_split)
  end
end