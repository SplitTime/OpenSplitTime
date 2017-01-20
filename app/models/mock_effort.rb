class MockEffort

  attr_reader :expected_time, :start_time

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:lap_splits, :expected_time, :start_time],
                           exclusive: [:lap_splits, :expected_time, :start_time, :finder, :times_calculator],
                           class: self.class)
    @lap_splits = args[:lap_splits]
    @expected_time = args[:expected_time]
    @start_time = args[:start_time]
    @finder = args[:effort_finder] || SimilarEffortFinder.new(sub_split: finish_sub_split,
                                                              time_from_start: expected_time,
                                                              finished: true)
    @times_planner = args[:times_planner] || SegmentTimesPlanner.new(lap_splits: lap_splits,
                                                                     expected_time: expected_time,
                                                                     similar_effort_ids: relevant_effort_ids,
                                                                     calc_model: :focused)
  end

  def indexed_split_times
    @indexed_split_times ||= ordered_time_points.map { |time_point| plan_split_time(time_point) }.index_by(&:time_point)
  end

  def split_rows
    @split_rows ||= plan_times.present? ? create_split_rows : []
  end

  def total_segment_time
    split_rows.sum(&:segment_time)
  end

  def total_time_in_aid
    split_rows.sum(&:time_in_aid)
  end

  def finish_time_from_start
    split_rows.last.times_from_start.first
  end

  def relevant_efforts_count
    relevant_effort_ids.size
  end

  def event_years_analyzed
    relevant_events.map(&:start_time).sort.map(&:year).uniq
  end

  def relevant_events
    @relevant_events ||= finder.events.to_a
  end

  def relevant_efforts
    @relevant_efforts ||= finder.efforts.to_a
  end

  private

  attr_accessor :relevant_split_times
  attr_reader :lap_splits, :finder, :times_planner

  def plan_split_time(time_point)
    SplitTime.new(time_point: time_point, time_from_start: plan_times[time_point])
  end

  def plan_times
    @plan_times ||= times_planner.times_from_start(round_to: 1.minute)
  end

  def create_split_rows
    prior_time = 0
    result = []
    lap_splits.each do |lap_split|
      split_row = SplitRow.new(lap_split: lap_split, split_times: related_split_times(lap_split),
                               prior_time: prior_time, start_time:  start_time)
      result << split_row
      prior_time = split_row.times_from_start.last
    end
    result
  end

  def related_split_times(lap_split)
    lap_split.time_points.map { |time_point| indexed_split_times[time_point] }
  end

  def finish_split
    lap_splits.last
  end

  def finish_sub_split
    finish_split.sub_split_in
  end

  def ordered_time_points
    lap_splits.map(&:time_points).flatten
  end

  def relevant_effort_ids
    finder.effort_ids
  end
end