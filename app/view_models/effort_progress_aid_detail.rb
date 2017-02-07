class EffortProgressAidDetail < EffortProgressRow

  def post_initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:effort, :event_framework, :lap, :effort_lap_split_times, :times_container],
                           exclusive: [:effort, :event_framework, :lap, :effort_lap_split_times, :times_container],
                           class: self.class)
    @lap = args[:lap]
    @effort_lap_split_times = args[:effort_lap_split_times]
    @times_container = args[:times_container]
    validate_setup
  end

  def expected_here_info
    EffortSplitData.new(split_name: lap_split_name(aid_station_time_points.first),
                        lap_name: lap_name(lap),
                        days_and_times: [effort.day_and_time(predicted_start_to_aid)])
  end

  def prior_to_here_info
    effort_split_data(prior_valid_split_time(aid_station_time_points.first))
  end

  def after_here_info
    effort_split_data(next_split_time(aid_station_time_points.last))
  end

  def recorded_in_here_info
    effort_split_data(indexed_split_times[aid_station_time_points.first])
  end

  def recorded_out_here_info
    effort_split_data(indexed_split_times[aid_station_time_points.last])
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
  attr_reader :lap, :effort_lap_split_times

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
    effort_lap_split_times.select { |st| st.lap_split_key == aid_station_lap_split_key }
  end

  def dropped_split_times
    effort_lap_split_times.select { |st| st.lap_split_key == dropped_lap_split_key }
  end

  def aid_station_lap_split_key
    LapSplitKey.new(lap, aid_station.split_id)
  end

  def dropped_lap_split_key
    LapSplitKey.new(effort.dropped_lap, effort.dropped_split_id)
  end

  def prior_valid_split_time(time_point)
    SplitTimeFinder.guaranteed_prior(time_point: time_point, lap_splits: lap_splits, split_times: effort_lap_split_times)
  end

  def next_split_time(time_point)
    SplitTimeFinder.next(time_point: time_point, lap_splits: lap_splits, split_times: effort_lap_split_times, valid: false)
  end

  def effort_split_data(split_times)
    split_times = Array.wrap(split_times)
    split_times.empty? ? {} : EffortSplitData.new(split_name: lap_split_name(split_times.first.time_point),
                                                  lap_name: lap_name(split_times.first.lap),
                                                  days_and_times: days_and_times(split_times))
  end

  def days_and_times(split_times)
    split_times.map { |split_time| effort.day_and_time(split_time.time_from_start) }
  end

  def indexed_split_times
    @indexed_split_times ||= effort_lap_split_times.index_by(&:time_point)
  end

  def validate_setup
    unless effort_lap_split_times.all? { |st| st.lap == lap }
      raise ArgumentError, "the following provided split_times conflict with provided lap #{lap}: " +
          "#{effort_lap_split_times.select { |st| st.lap != lap }.map(&:name)}"
    end
  end
end