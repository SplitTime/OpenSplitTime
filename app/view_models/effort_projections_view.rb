# frozen_string_literal: true

class EffortProjectionsView < EffortWithLapSplitRows
  delegate :simple?, :multiple_sub_splits?, to: :event
  delegate :effort_count, :effort_years, to: :projected_effort

  def actual_lap_split_rows
    @actual_lap_split_rows ||= lap_split_rows.elements_before(last_actual_lap_split_row, inclusive: true)
  end

  def projected_lap_split_rows
    @projected_lap_split_rows ||= rows_from_lap_splits(projected_lap_splits, indexed_projected_split_times, in_times_only: true)
  end

  def explanation
    case
    when !started?
      "The participant has not started."
    when !beyond_start?
      "The participant must first be recorded beyond the start."
    when effort_start_time.nil?
      "The participant does not have a recorded start time."
    when last_valid_split_time.nil?
      "The participant has recorded times but none are valid."
    when dropped?
      "The participant has dropped."
    when finished?
      "The participant has finished."
    else
      "Available data is insufficient."
    end
  end

  private

  def last_actual_lap_split_row
    lap_split_rows.reject(&:empty?).last
  end

  def projected_effort
    @projected_effort ||= ProjectedEffort.new(event: event,
                                              start_time: effort.actual_start_time,
                                              baseline_split_time: last_valid_split_time,
                                              projected_time_points: projected_time_points)
  end

  def last_valid_split_time
    ordered_split_times.select(&:valid_status?).last
  end

  def relevant_lap_splits
    lap_splits_plus_one
  end

  def projected_lap_splits
    return [] if indexed_projected_split_times.empty?
    relevant_lap_splits.elements_after(first_projected_lap_split, inclusive: true)
  end

  def relevant_time_points
    relevant_lap_splits.flat_map(&:time_points)
  end

  def projected_time_points
    return [] if finished? || dropped?
    relevant_time_points.elements_after(ordered_split_times.last.time_point).select(&:in_sub_split?)
  end

  def first_projected_lap_split
    relevant_lap_splits.find { |lap_split| lap_split.time_points.include?(first_projected_time_point) }
  end

  def first_projected_time_point
    projected_time_points.first
  end

  def indexed_projected_split_times
    return {} if effort_start_time.nil? || last_valid_split_time.nil?
    @indexed_projected_split_times ||= projected_effort.ordered_split_times.index_by(&:time_point)
  end
end
