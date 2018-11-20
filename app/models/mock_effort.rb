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
    @times_planner = args[:times_planner] || SegmentTimesPlanner.new(expected_time: expected_time,
                                                                     event: event,
                                                                     laps: expected_laps,
                                                                     similar_effort_ids: relevant_effort_ids,
                                                                     start_time: start_time)
  end

  def effort
    @effort ||= Effort.new(event: event)
  end

  def lap_split_rows
    plan_times.present? ? super : []
  end

  def total_segment_time
    lap_split_rows.map(&:segment_time).compact.sum
  end

  def finish_time_from_start
    ordered_split_times.last.absolute_time - start_time
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
    comparison_time_points.map { |tp| plan_split_times_data[tp] }
  end

  def all_ordered_split_times
    plan_split_times_data.values
  end

  # Normally SplitTimeData objects are created directly from a database query.
  # Because we are computing these SplitTimeData objects from data in memory,
  # we have to go through some gyrations to initialize the objects.

  def plan_split_times_data
    @plan_split_times_data ||= time_points_with_dummy.each_cons(2).map do |prior_time_point, time_point|
      prior_absolute_time = plan_times[prior_time_point]
      absolute_time = plan_times[time_point]
      absolute_time_string = absolute_time.to_s
      day_and_time = absolute_time.in_time_zone(time_zone)

      [time_point, SplitTimeData.new(effort_id: effort.id,
                                     lap: time_point.lap,
                                     split_id: time_point.split_id,
                                     bitkey: time_point.bitkey,
                                     absolute_time_string: absolute_time_string,
                                     day_and_time_string: day_and_time.to_s,
                                     time_from_start: absolute_time - start_time,
                                     segment_time: absolute_time - prior_absolute_time,
                                     military_time: day_and_time.strftime('%H:%M:%S'))]
    end.to_h
  end

  def plan_times
    @plan_times ||= times_planner.absolute_times(round_to: 1.minute)
  end

  def time_points_with_dummy
    [time_points.first] + time_points
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

  def time_zone
    event.home_time_zone
  end
end
