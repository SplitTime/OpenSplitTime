class EffortWithLapSplitRows
  attr_reader :effort

  def initialize(effort, options = {})
    post_initialize(effort, options)
  end

  def post_initialize(effort, options)
    ArgsValidator.validate(subject: effort, params: options, class: self.class)
    load_effort(effort)
  end

  def event
    @event ||= Event.where(id: effort.event_id).includes(:splits).first
  end

  def event_splits
    @event_splits ||= event.splits
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
    effort.actual_start_time
  end

  def progress_notifiable?
    effort.topic_resource_key.present? && !effort.stopped?
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

  def prior_id
    effort.prior_effort_id
  end

  def next_id
    effort.next_effort_id
  end

  def method_missing(method)
    effort.send(method)
  end

  private

  def difference(first_time, last_time)
    last_time && first_time && last_time - first_time
  end

  def rows_from_lap_splits(lap_splits, indexed_times, in_times_only: false)
    lap_splits.map do |lap_split|
      LapSplitRow.new(
        lap_split: lap_split,
        split_times: related_split_times(lap_split, indexed_times),
        show_laps: event.multiple_laps?,
        in_times_only: in_times_only,
        not_in_event: event_splits.exclude?(lap_split.split),
      )
    end
  end

  def related_split_times(lap_split, indexed_times)
    lap_split.time_points.map { |tp| indexed_times.fetch(tp, effort.split_times.new(time_point: tp)) }
  end

  def prior_split_time(lap_split)
    prior_time_points = time_points.elements_before(lap_split.time_point_in).to_set
    ordered_split_times.reverse.find { |st| prior_time_points.include?(st.time_point) }
  end

  def ordered_split_times
    @ordered_split_times ||= effort.ordered_split_times
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
    ordered_split_times.last&.lap || 1
  end

  private

  def load_effort(effort)
    temp_effort = Effort.where(id: effort).ranking_subquery.includes(split_times: :split).first
    AssignSegmentTimes.perform(temp_effort.ordered_split_times, :absolute_time)
    @effort = temp_effort
  end
end
