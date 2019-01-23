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
      effort.split_times.new(projected: true,
                             time_point: projection.time_point,
                             absolute_time: baseline_time + projection.average_seconds,
                             absolute_estimate_early: baseline_time + projection.low_seconds,
                             absolute_estimate_late: baseline_time + projection.high_seconds)
    end
  end

  private

  attr_reader :event, :start_time, :baseline_split_time, :projected_time_points

  def effort
    event.efforts.new
  end

  def projections
    @projections ||= SplitTimeQuery.projections(baseline_split_time, projected_time_points)
  end

  def baseline_time
    baseline_split_time.absolute_time
  end
end