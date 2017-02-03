class AidStationsDisplay < LiveEventFramework

  delegate :start_time, :course, :race, to: :event

  def post_initialize(args)
    ArgsValidator.validate(params: args, required: :event, exclusive: :event, class: self.class)
  end

  def aid_station_rows
    @aid_station_rows ||=
        aid_stations.map do |aid_station|
          AidStationRow.new(aid_station: aid_station,
                            event_data: self,
                            split_times: grouped_split_times[aid_station.split_id])
        end
  end

  def efforts_started_ids
    efforts_started.map(&:id)
  end

  def efforts_dropped_ids
    efforts_dropped.map(&:id)
  end

  def efforts_finished_ids
    efforts_finished.map(&:id)
  end

  def efforts_in_progress_ids
    efforts_in_progress.map(&:id)
  end

  private

  attr_reader :event

  def grouped_split_times
    @grouped_split_times ||= event.split_times
                                 .struct_pluck(:effort_id, :lap, :split_id, :sub_split_bitkey)
                                 .group_by(&:split_id)
  end

  def aid_stations
    @aid_stations ||= event.aid_stations.ordered.to_a[1..-1]
  end
end