class AidStationsDisplay

  attr_accessor :aid_station_rows
  attr_reader :live_event
  delegate :start_time, :course, :race, to: :event
  delegate :captain_name, :comms_chief_name, :comms_frequencies, to: :aid_station

  def initialize(event)
    @event = event
    @live_event = LiveEvent.new(@event)
    @aid_stations = @event.aid_stations.ordered.to_a[1..-1]
    @aid_station_rows = []
    @split_times_by_split = split_times.group_by(&:split_id)
    create_aid_station_details
  end

  def efforts_started_count
    efforts_started.count
  end

  def efforts_finished_count
    efforts_finished.count
  end

  def efforts_dropped_count
    efforts_dropped.count
  end

  def efforts_in_progress_count
    efforts_in_progress.count
  end

  def event_name
    event.name
  end

  def course_name
    course.name
  end

  def race_name
    race ? race.name : nil
  end

  def efforts_expected_count(aid_station)
    aid_station_detail = aid_station_rows.find { |row| row.split == aid_station.split }
    aid_station_detail.efforts_expected_count
  end

  def efforts_expected_count_next(aid_station)
    next_aid_station = aid_stations[aid_stations.index(aid_station) + 1]
    next_aid_station_detail = next_aid_station ? aid_station_rows.find { |row| row.split == next_aid_station.split } : nil
    next_aid_station_detail ? next_aid_station_detail.efforts_expected_count : 0
  end

  def split_name_next(aid_station)
    next_aid_station = aid_stations[aid_stations.index(aid_station) + 1]
    next_aid_station ? next_aid_station.split_name : ''
  end

  private

  attr_accessor :efforts_started
  attr_reader :event, :aid_stations, :split_times_by_split
  delegate :ordered_splits, :ordered_split_ids, :split_times, :efforts, :efforts_started,
           :efforts_finished, :efforts_dropped, :efforts_in_progress, to: :live_event

  def create_aid_station_details
    aid_stations.each do |aid_station|
      split_times = split_times_by_split[aid_station.split_id].group_by(&:effort_id)
      aid_station_row = AidStationDetail.new(aid_station, live_event, split_times)
      self.aid_station_rows << aid_station_row
    end
  end

end