# frozen_string_literal: true

class EffortWithLapSplitRows

  attr_reader :effort

  def initialize(args)
    post_initialize(args)
  end

  def post_initialize(args)
    ArgsValidator.validate(params: args, required: :effort, exclusive: :effort, class: self.class)
    @effort ||= args[:effort].enriched || args[:effort]
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
    @lap_split_rows ||= rows_from_lap_splits(lap_splits)
  end

  def lap_split_rows_plus_one
    @lap_split_rows_plus_one ||= rows_from_lap_splits(lap_splits_plus_one)
  end

  private

  def rows_from_lap_splits(lap_splits)
    lap_splits.map { |lap_split| LapSplitRow.new(lap_split: lap_split,
                                                 split_times: related_split_times(lap_split),
                                                 prior_split_time: prior_split_time(lap_split),
                                                 start_time: start_time,
                                                 show_laps: event.multiple_laps?) }
  end

  def related_split_times(lap_split)
    lap_split.time_points.map { |time_point| indexed_split_times[time_point] }
  end

  def prior_split_time(lap_split)
    prior_time_points = time_points.elements_before(lap_split.time_point_in).to_set
    ordered_split_times.select { |st| prior_time_points.include?(st.time_point) }.last
  end

  def start_time
    @start_time ||= event.start_time + effort.start_offset
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
    @loaded_effort ||= Effort.where(id: effort.id).includes(split_times: :split).includes(:event).includes(:person).first
  end
end
