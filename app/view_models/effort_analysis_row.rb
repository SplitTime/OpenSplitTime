# frozen_string_literal: true

class EffortAnalysisRow

  attr_reader :split_times
  delegate :distance_from_start, :lap, :split, :key, to: :lap_split
  delegate :kind, :intermediate?, :finish?, to: :split
  delegate :segment_time, :time_in_aid, :times_from_start, to: :time_cluster

  # split_times should be an array having size == split.sub_splits.size,
  # with nil values where no corresponding split_time exists

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:lap_split, :split_times, :start_time],
                           exclusive: [:lap_split, :split_times, :start_time, :show_laps,
                                       :prior_lap_split, :prior_split_time, :typical_row],
                           class: self.class)
    @lap_split = args[:lap_split]
    @split_times = args[:split_times]
    @prior_lap_split = args[:prior_lap_split]
    @prior_split_time = args[:prior_split_time]
    @start_time = args[:start_time]
    @typical_row = args[:typical_row]
    @show_laps = args[:show_laps]
  end

  def name
    show_laps? ? name_with_lap : name_without_lap
  end

  def time_cluster
    @time_cluster ||= TimeCluster.new(finish: split.finish?, split_times_data: split_times,
                                      prior_split_time: prior_split_time, start_time: start_time)
  end

  def split_id
    split.id
  end

  def segment_name
    show_laps? ? segment.name_with_lap : segment.name
  end

  def combined_time
    segment_time && segment_time + (time_in_aid || 0)
  end

  def segment_time_typical
    typical_row.try(:segment_time)
  end

  def time_in_aid_typical
    typical_row.try(:time_in_aid)
  end

  def combined_time_typical
    segment_time_typical && segment_time_typical + (time_in_aid_typical || 0)
  end

  def segment_time_over_under
    segment_time && segment_time_typical && segment_time - segment_time_typical
  end

  def time_in_aid_over_under
    time_in_aid && time_in_aid_typical && time_in_aid - time_in_aid_typical
  end

  def combined_time_over_under
    segment_time_over_under && time_in_aid_over_under && segment_time_over_under + time_in_aid_over_under
  end

  def segment_over_under_percent
    segment_time_over_under && segment_time_typical && segment_time_over_under / segment_time_typical
  end

  private

  attr_reader :lap_split, :prior_lap_split, :prior_split_time, :start_time, :typical_row

  def segment
    @segment ||= end_time_point && Segment.new(begin_point: prior_split_time.time_point,
                                               end_point: end_time_point,
                                               begin_lap_split: prior_lap_split,
                                               end_lap_split: lap_split)
  end

  def end_time_point
    split_times.compact.first.try(:time_point)
  end

  def show_laps?
    @show_laps
  end

  def name_without_lap
    lap_split.base_name_without_lap
  end

  def name_with_lap
    lap_split.base_name
  end
end
