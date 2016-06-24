class AidStationsDisplay

  attr_accessor :aid_station_rows
  delegate :start_time, :course, :race, to: :event
  delegate :captain_name, :comms_chief_name, :comms_frequencies, to: :aid_station

  def initialize(event)
    @event = event
    @aid_stations = event.aid_stations.ordered.to_a[1..-1]
    @splits = event.splits.ordered.to_a
    @efforts = event.efforts.sorted_with_finish_status
    @aid_station_rows = []
    @ordered_split_ids = @splits.map(&:id)
    get_split_times
    set_efforts_started
    create_efforts_displays
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

  private

  attr_accessor :event_split_times, :efforts_started
  attr_reader :event, :aid_stations, :splits, :efforts, :ordered_split_ids

  def get_split_times
    self.event_split_times = SplitTime.select(:id, :sub_split_bitkey, :split_id, :time_from_start, :data_status)
                                 .where(effort_id: efforts.map(&:id))
                                 .ordered
                                 .group_by(&:split_id)
  end

  def set_efforts_started
    started_effort_ids = event_split_times[start_split_id].map(&:effort_id)
    self.efforts_started = efforts.select { |effort| started_effort_ids.include?(effort.id) }
  end

  def create_efforts_displays
    aid_stations.each do |aid_station|
      split_times = event_split_times[aid_station.split_id].group_by(&:effort_id)
      aid_station_row = AidStationDetail.new(aid_station, efforts_started, split_times, ordered_split_ids)
      self.aid_station_rows << aid_station_row
    end
  end

  def efforts_finished
    efforts_started.select { |effort| effort.final_split_id == finish_split_id }
  end

  def efforts_dropped
    efforts_started.select { |effort| effort.dropped_split_id.present? }
  end

  def efforts_in_progress
    efforts_started.select { |effort| effort.dropped_split_id.nil? && (effort.final_split_id != finish_split_id) }
  end

  def start_split_id
    ordered_split_ids.first
  end

  def finish_split_id
    ordered_split_ids.last
  end

end