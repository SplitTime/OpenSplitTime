# frozen_string_literal: true

class TypicalEffort
  attr_reader :event, :expected_time_from_start, :start_time, :similar_effort_finder

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :expected_time_from_start, :start_time, :time_points],
                           exclusive: [:event, :expected_time_from_start, :start_time, :time_points,
                                       :expected_time_point, :similar_effort_finder, :times_planner],
                           class: self.class)
    @event = args[:event]
    @expected_time_from_start = args[:expected_time_from_start]
    @start_time = args[:start_time]
    @time_points = args[:time_points]
    @expected_time_point = args[:expected_time_point] || time_points.last
    @similar_effort_finder = args[:similar_effort_finder] || SimilarEffortFinder.new(time_point: last_time_point,
                                                                                     time_from_start: expected_time_from_start,
                                                                                     finished: true)
    @times_planner = args[:times_planner] || SegmentTimesPlanner.new(expected_time: expected_time_from_start,
                                                                     event: event,
                                                                     time_points: time_points,
                                                                     similar_effort_ids: relevant_effort_ids,
                                                                     start_time: start_time)
  end

  def effort
    @effort ||= event.efforts.new
  end

  def ordered_split_times
    @ordered_split_times ||= plan_times.map do |time_point, absolute_time|
      effort.split_times.new(time_point: time_point, absolute_time: absolute_time)
    end
  end

  private

  attr_reader :time_points, :expected_time_point, :times_planner

  def plan_times
    @plan_times ||= times_planner.absolute_times(round_to: 1.minute)
  end

  def last_time_point
    time_points.last
  end

  def relevant_effort_ids
    similar_effort_finder.effort_ids
  end
end
