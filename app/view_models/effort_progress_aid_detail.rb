class EffortProgressAidDetail < EffortProgressFramework

  def post_initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:effort, :event_framework, :split_times],
                           exclusive: [:effort, :event_framework, :split_times],
                           class: self.class)
    @split_times = args[:split_times]
  end

  def expected_here_day_and_time
    effort.day_and_time(predicted_start_to_aid)
  end

  def prior_valid_display_data
    "#{lap_split_name(prior_valid_time_point)} at"
  end

  def dropped_days_and_times
    dropped_split_times.map { |st| effort.start_time + st.time_from_start }
  end

  def extract_attributes(*attributes)
    attributes.map { |attribute| [attribute, send(attribute)] }.to_h
  end

  private

  delegate :aid_station, :time_points, to: :event_framework
  delegate :state_and_country, to: :effort
  attr_reader :split_times

  def predicted_start_to_aid
    predicted_time_to_aid && (effort.final_time + predicted_time_to_aid)
  end

  def predicted_time_to_aid
    @predicted_time_to_aid ||= predicted_segment_time(latest_to_aid_station)
  end

  def latest_to_aid_station
    Segment.new(begin_point: last_reported_time_point, end_point: aid_station_time_point_in)
  end

  def aid_station_time_point_in
    time_points_beyond_last.find { |time_point| time_point.split_id == aid_station.split_id }
  end

  def time_points_beyond_last
    time_points[last_reported_time_point_index + 1..-1]
  end

  def prior_valid_time_point
    prior_valid_split_time.time_point
  end

  def prior_valid_split_time
    PriorSplitTimeFinder.guaranteed_split_time(time_point: aid_station_time_point_in,
                                               lap_splits: lap_splits,
                                               split_times: split_times)
  end

  def split_time_prior_to_drop
    dropped_split_times
  end

  def dropped_split_times
    split_times.select { |st| st.lap_split_key == dropped_lap_split_key }
  end

  def dropped_lap_split_key
    LapSplitKey.new(effort.dropped_lap, effort.dropped_split_id)
  end
end