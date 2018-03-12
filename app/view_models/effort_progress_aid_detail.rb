# frozen_string_literal: true

class EffortProgressAidDetail < EffortProgressRow

  def post_initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:effort, :event_framework, :lap, :effort_split_times, :times_container],
                           exclusive: [:effort, :event_framework, :lap, :effort_split_times, :times_container],
                           class: self.class)
    @lap = args[:lap]
    @effort_split_times = args[:effort_split_times]
    @times_container = args[:times_container]
  end

  def expected_here_info
    EffortSplitData.new(effort_slug: effort_slug,
                        lap_name: lap_name(lap),
                        split_name: lap_split_name(aid_station_time_points.first),
                        days_and_times: [effort.day_and_time(predicted_start_to_aid)])
  end

  def prior_to_here_info
    effort_split_data(lap, prior_valid_split_time(aid_station_time_points.first))
  end

  def after_here_info
    effort_split_data(lap, next_split_time(aid_station_time_points.last))
  end

  def recorded_here_info
    effort_split_data(lap, recorded_here_split_times)
  end

  def stopped_here_info
    effort_split_data(lap, stopped_here_split_times)
  end

  def dropped_here_info
    effort_split_data(lap, dropped_here_split_times)
  end

  private

  delegate :aid_station, :split_name, :time_points, :multiple_laps?, to: :event_framework
  delegate :split, to: :aid_station
  delegate :state_and_country, to: :effort
  attr_reader :lap, :effort_split_times

  def predicted_start_to_aid
    predicted_time_to_aid && (effort.final_time + predicted_time_to_aid)
  end

  def predicted_time_to_aid
    @predicted_time_to_aid ||= predicted_segment_time(latest_to_aid_station)
  end

  def latest_to_aid_station
    Segment.new(begin_point: last_reported_time_point, end_point: aid_station_time_points.first)
  end

  def aid_station_time_points
    split.bitkeys.map { |bitkey| TimePoint.new(lap, split.id, bitkey) }
  end

  def stopped_time_points
    indexed_lap_splits[LapSplitKey.new(effort.stopped_lap, effort.stopped_split_id)].time_points
  end

  def recorded_here_split_times
    aid_station_time_points.map { |time_point| indexed_split_times[time_point] }
  end

  def stopped_here_split_times
    stopped_time_points.map { |time_point| indexed_split_times[time_point] }
  end

  def dropped_here_split_times
    stopped_time_points.map { |time_point| indexed_split_times[time_point] }
  end

  def prior_valid_split_time(time_point)
    SplitTimeFinder.prior(time_point: time_point, lap_splits: lap_splits, split_times: effort_split_times)
  end

  def next_split_time(time_point)
    SplitTimeFinder.next(time_point: time_point, lap_splits: lap_splits, split_times: effort_split_times, valid: false)
  end

  def indexed_split_times
    @indexed_split_times ||= effort_split_times.index_by(&:time_point)
  end
end
