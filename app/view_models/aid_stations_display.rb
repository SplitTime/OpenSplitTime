class AidStationsDisplay < LiveEventFramework
  delegate :course, :organization, :home_time_zone, to: :event

  def post_initialize(args)
    raise ArgumentError, "aid_stations_display must include event" unless args[:event]
  end

  def aid_station_rows
    @aid_station_rows ||=
      aid_stations.map do |aid_station|
        AidStationRow.new(aid_station: aid_station,
                          event_framework: self,
                          split_times: grouped_split_times[aid_station.split_id] || [])
      end
  end

  def start_time
    event.scheduled_start_time_local
  end

  private

  def grouped_split_times
    @grouped_split_times ||= event.split_times
                                  .select(:effort_id, :lap, :split_id, :sub_split_bitkey)
                                  .group_by(&:split_id)
  end

  def aid_stations
    @aid_stations ||= event.aid_stations.ordered.to_a
  end
end
