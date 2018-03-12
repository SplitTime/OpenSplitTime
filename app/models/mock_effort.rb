# frozen_string_literal: true

class MockEffort < EffortWithLapSplitRows

  attr_reader :event, :expected_time, :start_time

  def post_initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :expected_time, :start_time],
                           exclusive: [:event, :expected_time, :start_time, :comparison_time_points,
                                       :expected_laps, :effort_finder, :times_planner],
                           class: self.class)
    @event = args[:event]
    @expected_time = args[:expected_time]
    @start_time = args[:start_time]
    @comparison_time_points = args[:comparison_time_points]
    @expected_laps = args[:expected_laps]
    @effort_finder = args[:effort_finder] || SimilarEffortFinder.new(time_point: finish_time_point,
                                                              time_from_start: expected_time,
                                                              finished: true)
    @times_planner = args[:times_planner] || SegmentTimesPlanner.new(lap_splits: lap_splits,
                                                                     expected_time: expected_time,
                                                                     similar_effort_ids: relevant_effort_ids,
                                                                     calc_model: :focused)
  end

  def effort
    Effort.new
  end

  def lap_split_rows
     plan_times.present? ? super : []
  end

  def total_segment_time
    lap_split_rows.map(&:segment_time).compact.sum
  end

  def finish_time_from_start
    ordered_split_times.map(&:time_from_start).last
  end

  def relevant_efforts_count
    relevant_effort_ids.size
  end

  def event_years_analyzed
    relevant_events.map(&:start_time).sort.map(&:year).uniq
  end

  def relevant_events
    @relevant_events ||= effort_finder.events.to_a
  end

  def relevant_efforts
    @relevant_efforts ||= effort_finder.efforts.to_a
  end

  private

  attr_reader :comparison_time_points, :expected_laps, :effort_finder, :times_planner

  def ordered_split_times
    @ordered_split_times ||= comparison_time_points.present? ?
        comparison_ordered_split_times : all_ordered_split_times
  end

  def comparison_ordered_split_times
    all_ordered_split_times.select { |st| comparison_time_points.include?(st.time_point) }
  end

  def all_ordered_split_times
    time_points.map { |time_point| plan_split_time(time_point) }
  end

  def plan_split_time(time_point)
    SplitTime.new(time_point: time_point, time_from_start: plan_times[time_point])
  end

  def plan_times
    @plan_times ||= times_planner.times_from_start(round_to: 1.minute)
  end

  def finish_time_point
    time_points.last
  end

  def relevant_effort_ids
    effort_finder.effort_ids
  end

  def last_lap
    expected_laps || (comparison_time_points && comparison_time_points.map(&:lap).last) || 1
  end
end