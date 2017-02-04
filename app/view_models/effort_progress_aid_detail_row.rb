class EffortProgressAidDetailRow < EffortProgressFramework

  def post_initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:effort, :event_framework],
                           exclusive: [:effort, :event_framework],
                           class: self.class)
  end

  def expected_here_day_and_time
    determine_day_and_time(predicted_time_to_aid)
  end

  def dropped_day_and_time
    recorded_day_and_time(dropped_time_point)
  end

  private

  delegate :aid_station, :split_times_by_effort, to: :event_framework

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

  def dropped_time_point
    effort_split_times.select { |st| st.split_id == effort.dropped_split_id }.last.try(:time_point)
  end

  def recorded_day_and_time(time_point)
    split_time = effort_split_times.index_by(&:time_point)[time_point]
    split_time && effort.start_time + split_time.time_from_start
  end

  def effort_split_times
    @effort_split_times ||= split_times_by_effort[effort.id]
  end
end