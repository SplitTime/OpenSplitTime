class AidStationsDisplay < LiveEventFramework

  delegate :start_time, :course, :race, to: :event

  def post_initialize(args)
    nil
  end

  def aid_station_rows
    @aid_station_rows ||=
        aid_stations.map { |aid_station| AidStationRow.new(aid_station: aid_station,
                                                           event_data: self) }
  end

  EFFORT_CATEGORIES.each do |category|
    define_method("efforts_#{category}_ids") do
      efforts.select { |effort| effort.send("#{category}?") }.map(&:id)
    end
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

  attr_reader :event

  def aid_stations
    @aid_stations ||= event.aid_stations.ordered.to_a[1..-1]
  end
end