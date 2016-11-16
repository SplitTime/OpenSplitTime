class TimeFromStartPredictor

  def initialize(effort, sub_split, options = {})
    @effort = effort
    @sub_split = sub_split
    @options = options
    validate_predictor
  end

  def predicted_time
    sub_split_start? ? 0 : seconds_from_start
  end

  private

  attr_reader :effort, :sub_split, :options

  def prior_sub_split
    prior_split_time.sub_split
  end

  def prior_split_time
    relevant_sub_splits.reverse.find { |sub_split| indexed_split_times[sub_split] }
  end

  def relevant_sub_splits
    ordered_sub_splits[0..ordered_sub_splits.index(sub_split) - 1]
  end

  def ordered_splits
    @ordered_splits ||= options[:ordered_splits] || event.ordered_splits.to_a
  end

  def ordered_sub_splits
    @ordered_sub_splits ||= ordered_splits.map(&:sub_splits).flatten
  end

  def indexed_split_times
    @indexed_split_times ||= valid_split_times.index_by(&:sub_split)
  end

  def valid_split_times
    @valid_split_times ||= effort.split_times.valid_status.to_a
  end

  def start_sub_split
    ordered_sub_splits.first
  end

  def sub_split_start?
    sub_split == start_sub_split
  end

  def validate_predictor
    raise RuntimeError 'Effort has not started' unless indexed_split_times[start_sub_split].present?
  end
end

def expected_time_from_start
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
