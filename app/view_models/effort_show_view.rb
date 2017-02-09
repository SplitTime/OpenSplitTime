class EffortShowView

  attr_reader :effort, :split_rows
  delegate :full_name, :event_name, :participant, :bib_number, :gender, :split_times,
           :finish_status, :report_url, :beacon_url, :dropped_split_id, :start_time, :photo_url,
           :overall_place, :gender_place, :started?, :finished?, :dropped?, :in_progress?, to: :effort
  delegate :simple?, to: :event

  def initialize(args_effort)
    @effort ||= args_effort.enriched || args_effort
    @split_rows = []
    create_split_rows
  end

  def event
    @event ||= effort.event
  end

  def total_time_in_aid
    split_rows.sum(&:time_in_aid)
  end

  def not_analyzable?
    ordered_split_times.size < 2
  end

  private

  attr_reader :splits

  def create_split_rows
    start_time = event.start_time + effort.start_offset
    prior_time = 0
    lap_splits.each do |lap_split|
      split_row = LapSplitRow.new(lap_split: lap_split, split_times: related_split_times(lap_split),
                                  prior_time: prior_time, start_time: start_time, show_laps: event.multiple_laps?)
      split_rows << split_row
      prior_time = split_row.times_from_start.compact.last if split_row.times_from_start.compact.present?
    end
  end

  def related_split_times(lap_split)
    lap_split.time_points.map { |time_point| indexed_split_times[time_point] }
  end

  def ordered_splits
    @ordered_splits ||= effort.ordered_splits.to_a
  end

  def ordered_split_times
    @ordered_split_times ||= effort.ordered_split_times.to_a
  end

  def indexed_split_times
    @indexed_split_times ||= ordered_split_times.index_by(&:time_point)
  end

  def lap_splits
    @lap_splits ||= event.required_lap_splits.presence || event.lap_splits_through(last_lap)
  end

  def last_lap
    ordered_split_times.map(&:lap).last || 1
  end
end