class EffortProgressAidDetail < EffortProgressRow

  def post_initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:effort, :event_framework, :lap, :split_times, :times_container],
                           exclusive: [:effort, :event_framework, :lap, :split_times, :times_container],
                           class: self.class)
    @lap = args[:lap]
    @split_times = args[:split_times]
    @times_container = args[:times_container]
  end

  def expected_here_info
    {day_and_time: effort.day_and_time(predicted_start_to_aid), split_name: split_name}
  end

  def prior_to_here_info
    display_data(prior_valid_split_time(aid_station_time_points.first))
  end

  def after_here_info
    display_data(next_split_time(aid_station_time_points.last))
  end

  def recorded_in_here_info
    display_data(indexed_split_times[aid_station_time_points.first])
  end

  def recorded_out_here_info
    display_data(indexed_split_times[aid_station_time_points.last])
  end

  def recorded_here_days_and_times
    recorded_here_split_times.map { |st| effort.day_and_time(st.time_from_start) }
  end

  def dropped_days_and_times
    dropped_split_times.map { |st| [effort.dropped_lap, effort.day_and_time(st.time_from_start)] }.to_h
  end

  private

  delegate :aid_station, :split_name, :time_points, :multiple_laps?, to: :event_framework
  delegate :state_and_country, to: :effort
  attr_reader :lap, :split_times

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
    aid_station.split.bitkeys.map { |bitkey| TimePoint.new(lap, aid_station.split_id, bitkey) }
  end

  def recorded_here_split_times
    split_times.select { |st| st.lap_split_key == aid_station_lap_split_key }
  end

  def dropped_split_times
    split_times.select { |st| st.lap_split_key == dropped_lap_split_key }
  end

  def aid_station_lap_split_key
    LapSplitKey.new(lap, aid_station.split_id)
  end

  def dropped_lap_split_key
    LapSplitKey.new(effort.dropped_lap, effort.dropped_split_id)
  end

  def prior_valid_split_time(time_point)
    SplitTimeFinder.guaranteed_prior(time_point: time_point, lap_splits: lap_splits, split_times: split_times)
  end

  def next_split_time(time_point)
    SplitTimeFinder.next(time_point: time_point, lap_splits: lap_splits, split_times: split_times, valid: false)
  end

  def display_data(split_times)
    (split_times || []).map { |split_time| {split_name: lap_split_name(split_time.time_point),
                                            lap: "Lap #{lap}",
                                            day_and_time: effort.day_and_time(split_time.time_from_start)} }
  end

  def indexed_split_times
    @indexed_split_times ||= split_times.index_by(&:time_point)
  end
end