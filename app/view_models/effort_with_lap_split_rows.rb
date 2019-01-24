# frozen_string_literal: true

class EffortWithLapSplitRows
  attr_reader :effort

  def initialize(effort, options = {})
    post_initialize(effort, options)
  end

  def post_initialize(effort, options)
    ArgsValidator.validate(subject: effort, params: options, class: self.class)
    @effort = effort.enriched
  end

  def event
    @event ||= Event.where(id: effort.event_id).includes(:efforts, :splits).first
  end

  def total_time_in_aid
    lap_split_rows.map(&:time_in_aid).compact.sum
  end

  def not_analyzable?
    ordered_split_times.size < 2
  end

  def lap_split_rows
    @lap_split_rows ||= rows_from_lap_splits(lap_splits, indexed_split_times)
  end

  def lap_split_rows_plus_one
    @lap_split_rows_plus_one ||= rows_from_lap_splits(lap_splits_plus_one, indexed_split_times)
  end

  def effort_start_time
    effort.start_time
  end

  def true_lap_time(lap)
    lap_start_row = lap_split_rows.find { |row| row.start? && row.lap == lap }
    lap_finish_row = lap_split_rows.find { |row| row.finish? && row.lap == lap }
    difference(lap_start_row&.times_from_start&.first, lap_finish_row&.times_from_start&.first)
  end

  def provisional_lap_time(lap)
    prior_lap_row = lap_split_rows.find { |row| row.finish? && row.lap == lap - 1 }
    lap_row = lap_split_rows.find { |row| row.finish? && row.lap == lap }
    difference(prior_lap_row&.times_from_start&.first, lap_row&.times_from_start&.first)
  end

  def method_missing(method)
    effort.send(method)
  end

  private

  def difference(first_time, last_time)
    last_time && first_time && last_time - first_time
  end

  def rows_from_lap_splits(lap_splits, indexed_times)
    lap_splits.map do |lap_split|
      LapSplitRow.new(lap_split: lap_split,
                      split_times: related_split_times(lap_split, indexed_times),
                      show_laps: event.multiple_laps?)
    end
  end

  def related_split_times(lap_split, indexed_times)
    lap_split.time_points.map { |time_point| indexed_times.fetch(time_point, effort.split_times.new) }
  end

  def prior_split_time(lap_split)
    prior_time_points = time_points.elements_before(lap_split.time_point_in).to_set
    ordered_split_times.reverse.find { |st| prior_time_points.include?(st.time_point) }
  end

  def ordered_split_times
    @ordered_split_times ||= loaded_effort.ordered_split_times
  end

  def indexed_split_times
    @indexed_split_times ||= ordered_split_times.index_by(&:time_point)
  end

  def time_points
    @time_points ||= lap_splits.flat_map(&:time_points)
  end

  def lap_splits
    @lap_splits ||= lap_splits_from_lap(last_lap)
  end

  def lap_splits_plus_one
    @lap_splits_plus_one ||= lap_splits_from_lap(last_lap + 1)
  end

  def lap_splits_from_lap(lap)
    event.required_lap_splits.presence || event.lap_splits_through(lap)
  end

  def last_lap
    ordered_split_times.map(&:lap).last || 1
  end

  def loaded_effort
    return @loaded_effort if defined?(@loaded_effort)
    temp_effort = Effort.where(id: effort).includes(:event, :person, split_times: :split).first
    AssignSegmentTimes.perform(temp_effort.ordered_split_times, :absolute_time)
    @loaded_effort = temp_effort
  end
end
