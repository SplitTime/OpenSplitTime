class TimePredictor
  def self.segment_time(segment:, effort:, lap_splits: nil, completed_split_time: nil,
                        calc_model: nil, similar_effort_ids: nil, times_container: nil)
    new(
      segment: segment,
      effort: effort,
      lap_splits: lap_splits,
      completed_split_time: completed_split_time,
      calc_model: calc_model,
      similar_effort_ids: similar_effort_ids,
      times_container: times_container
    ).segment_time
  end

  def initialize(segment:, effort:, lap_splits: nil, completed_split_time: nil,
                 calc_model: nil, similar_effort_ids: nil, times_container: nil)
    raise ArgumentError, "time_predictor must include segment" unless segment
    raise ArgumentError, "time_predictor must include effort" unless effort

    @segment = segment
    @effort = effort
    @lap_splits = lap_splits || effort.lap_splits
    @similar_effort_ids = similar_effort_ids
    @times_container = times_container ||
                       SegmentTimesContainer.new(calc_model: calc_model, effort_ids: similar_effort_ids)
    @calc_model = calc_model || @times_container.calc_model || :terrain
    @completed_split_time = completed_split_time || last_valid_split_time || mock_start_split_time
    validate_setup
  end

  def segment_time
    uncorrected_segment_time && (uncorrected_segment_time * pace_factor)
  end

  def data_status(seconds)
    DataStatus.determine(limits, seconds)
  end

  private

  attr_reader :segment, :effort, :lap_splits, :completed_split_time, :calc_model, :similar_effort_ids, :times_container

  def uncorrected_segment_time
    times_container.segment_time(segment)
  end

  def limits
    times_container.limits(segment).transform_values { |limit| (limit * pace_factor).to_i }
  end

  def pace_factor
    @pace_factor ||= measurable_pace? ? actual_completed_time / typical_completed_time : 1
  end

  def measurable_pace?
    completed_lap_split.distance_from_start.positive? && actual_completed_time && typical_completed_time
  end

  def actual_completed_time
    completed_split_time.absolute_time && effort.actual_start_time &&
      (completed_split_time.absolute_time - effort.actual_start_time)
  end

  def typical_completed_time
    times_container.segment_time(completed_segment)
  end

  def completed_segment
    Segment.new(begin_point: start_lap_split.time_point_in, end_point: completed_time_point,
                begin_lap_split: start_lap_split, end_lap_split: completed_lap_split)
  end

  def start_lap_split
    @start_lap_split ||= lap_splits.first
  end

  def completed_time_point
    @completed_time_point ||= completed_split_time.time_point
  end

  def completed_lap_split
    @completed_lap_split ||= lap_splits.find { |lap_split| lap_split.key == completed_split_time.lap_split_key }
  end

  def last_valid_split_time
    @last_valid_split_time ||= effort.ordered_split_times.select { |st| st.time_from_start && st.valid_status? }.last
  end

  def mock_start_split_time
    SplitTime.new(time_point: start_lap_split.time_point_in, time_from_start: 0)
  end

  def validate_setup
    raise ArgumentError, "completed_split_time is not associated with the splits" unless completed_lap_split
  end
end
