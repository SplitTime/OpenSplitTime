# frozen_string_literal: true

class EffortAnalysisRow

  attr_reader :split_times, :typical_split_times
  delegate :distance_from_start, :lap, :split, to: :lap_split
  delegate :kind, :intermediate?, :finish?, to: :split
  delegate :segment_time, :time_in_aid, :times_from_start, to: :time_cluster

  # split_times should be an array having size == split.sub_splits.size,
  # with nil values where no corresponding split_time exists

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:lap_split, :split_times, :typical_split_times, :start_time],
                           exclusive: [:lap_split, :split_times, :typical_split_times, :start_time, :show_laps,
                                       :prior_lap_split, :prior_split_time],
                           class: self.class)
    @lap_split = args[:lap_split]
    @split_times = args[:split_times]
    @typical_split_times = args[:typical_split_times]
    @prior_lap_split = args[:prior_lap_split]
    @prior_split_time = args[:prior_split_time]
    @start_time = args[:start_time]
    @show_laps = args[:show_laps]
  end

  def name
    show_laps? ? name_with_lap : name_without_lap
  end

  def time_cluster
    @time_cluster ||= TimeCluster.new(finish: split.finish?, split_times_data: split_times)
  end

  def typical_time_cluster
    @typical_time_cluster ||= TimeCluster.new(finish: split.finish?, split_times_data: typical_split_times)
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
    typical_time_cluster.segment_time
  end

  def time_in_aid_typical
    typical_time_cluster.time_in_aid
  end

  def combined_time_typical
    segment_time_typical && segment_time_typical + (time_in_aid_typical || 0)
  end

  def segment_time_over_under(round_to: 1.second)
    return nil unless segment_time && segment_time_typical

    segment_time.round_to_nearest(round_to) - segment_time_typical.round_to_nearest(round_to)
  end

  def time_in_aid_over_under(round_to: 1.second)
    return nil unless time_in_aid && time_in_aid_typical

    time_in_aid.round_to_nearest(round_to) - time_in_aid_typical.round_to_nearest(round_to)
  end

  def combined_time_over_under(round_to: 1.second)
    return nil unless segment_time_over_under && time_in_aid_over_under

    segment_time_over_under.round_to_nearest(round_to) + time_in_aid_over_under.round_to_nearest(round_to)
  end

  def segment_over_under_percent
    segment_time_over_under && segment_time_typical && segment_time_over_under / segment_time_typical
  end

  private

  attr_reader :lap_split, :prior_lap_split, :prior_split_time, :start_time

  def segment
    @segment ||= end_time_point && Segment.new(begin_point: prior_split_time.time_point,
                                               end_point: end_time_point,
                                               begin_lap_split: prior_lap_split,
                                               end_lap_split: lap_split)
  end

  def end_time_point
    split_times.compact.select(&:split_id).first&.time_point
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
