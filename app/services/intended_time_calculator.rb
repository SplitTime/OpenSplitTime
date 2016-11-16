class IntendedTimeCalculator

  def initialize(military_time, effort, sub_split, options = {})
    @military_time = military_time
    @effort = effort
    @sub_split = sub_split
    @event = options[:event] || effort.event
  end

  def intended_time
    return nil if seconds_into_day >= 1.day
    expected_day_and_time &&
        earliest_datetime + ((((earliest_datetime - expected_day_and_time) * -1) / 1.day).round(0) * 1.day)
  end

  private

  attr_reader :military_time, :effort, :sub_split, :event

  def expected_day_and_time
    expected_time_from_start && start_time + expected_time_from_start
  end

  def expected_time_from_start
    split_times_hash = split_times.index_by(&:sub_split)
    ordered_splits = event.ordered_splits.to_a
    ordered_sub_splits = ordered_splits.map(&:sub_splits).flatten
    start_sub_split = ordered_sub_splits.first
    return nil unless split_times_hash[start_sub_split].present?
    return 0 if sub_split == start_sub_split
    relevant_sub_splits = ordered_sub_splits[0..(ordered_sub_splits.index(sub_split) - 1)]
    prior_split_time = relevant_sub_splits.collect { |sub_split| split_times_hash[sub_split] }.compact.last
    prior_sub_split = prior_split_time.sub_split
    event_segment_calcs ||= EventSegmentCalcs.new(event)
    completed_segment = Segment.new(start_sub_split,
                                    prior_sub_split,
                                    ordered_splits.find { |split| split.id == start_sub_split.split_id },
                                    ordered_splits.find { |split| split.id == prior_sub_split.split_id })
    subject_segment = Segment.new(prior_sub_split,
                                  sub_split,
                                  ordered_splits.find { |split| split.id == prior_sub_split.split_id },
                                  ordered_splits.find { |split| split.id == sub_split.split_id })
    completed_segment_calcs = event_segment_calcs.fetch_calculations(completed_segment)
    subject_segment_calcs = event_segment_calcs.fetch_calculations(subject_segment)
    pace_baseline = completed_segment_calcs.mean ?
        completed_segment_calcs.mean :
        completed_segment.typical_time_by_terrain
    pace_factor = pace_baseline == 0 ? 1 :
        prior_split_time.time_from_start / pace_baseline
    subject_segment_calcs.mean ?
        (prior_split_time.time_from_start + (subject_segment_calcs.mean * pace_factor)) :
        (prior_split_time.time_from_start + (subject_segment.typical_time_by_terrain * pace_factor))
  end

  def earliest_datetime
    start_time.beginning_of_day + seconds_into_day
  end

  def start_time
    @start_time ||= effort.start_time
  end

  def seconds_into_day
    TimeConversion.hms_to_seconds(military_time)
  end

end