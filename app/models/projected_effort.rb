# frozen_string_literal: true

class ProjectedEffort
  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :start_time, :baseline_split_time, :projected_time_points],
                           exclusive: [:event, :start_time, :baseline_split_time, :projected_time_points],
                           class: self)
    @event = args[:event]
    @start_time = args[:start_time]
    @baseline_split_time = args[:baseline_split_time]
    @projected_time_points = args[:projected_time_points]
  end

  def ordered_split_times
    @ordered_split_times ||= projections.map do |projection|
      effort.split_times.new(time_point: projection.time_point,
                             absolute_time: add_to_baseline(projection.average_seconds),
                             absolute_estimate_early: add_to_baseline(projection.low_seconds),
                             absolute_estimate_late: add_to_baseline(projection.high_seconds))
    end
  end

  def effort_years
    projections.flat_map(&:effort_years).uniq.sort
  end

  def effort_count
    projections.map(&:effort_count).max
  end

  private

  attr_reader :event, :start_time, :baseline_split_time, :projected_time_points
  delegate :starting_time_point, to: :event

  def effort
    event.efforts.new
  end

  def projections
    @projections ||= Projection.execute_query(baseline_split_time, starting_time_point, projected_time_points)
  end

  def baseline_time
    baseline_split_time.absolute_time
  end

  def add_to_baseline(seconds)
    seconds && baseline_time + seconds
  end
end
