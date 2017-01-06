class AidStationsDisplay

  attr_reader :live_event
  delegate :start_time, :course, :race, to: :event
  delegate :captain_name, :comms_crew_names, :comms_frequencies, to: :aid_station

  def initialize(event)
    @event = event
    @live_event = LiveEvent.new(@event)
    @aid_stations = @event.aid_stations.ordered.to_a[1..-1]
    @split_times_by_split = split_times.group_by(&:split_id)
    @split_times_by_split.default = []
  end

  def aid_station_rows
    @aid_station_rows ||=
        aid_stations.map { |aid_station| AidStationDetail.new(aid_station: aid_station,
                                                              live_event: live_event,
                                                              indexed_split_times: split_times_by_effort(aid_station)) }
  end

  def split_times_by_effort(aid_station)
    hash = split_times_by_split[aid_station.split_id].group_by(&:effort_id)
    hash.default = []
    hash
  end

  def efforts_started_count
    efforts_started.size
  end

  def efforts_finished_count
    efforts_finished.size
  end

  def efforts_dropped_count
    efforts_dropped.size
  end

  def efforts_in_progress_count
    efforts_in_progress.size
  end

  def event_name
    event.name
  end

  def course_name
    course.name
  end

  def race_name
    race && race.name
  end

  def efforts_expected_count(aid_station)
    aid_station_rows.find { |row| row.split == aid_station.split }.efforts_expected_count
  end

  def efforts_expected_count_next(aid_station)
    next_aid_station = aid_stations[aid_stations.index(aid_station) + 1]
    next_aid_station_row = next_aid_station && aid_station_rows.find { |row| row.split == next_aid_station.split }
    next_aid_station_row ? next_aid_station_row.efforts_expected_count : 0
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
end