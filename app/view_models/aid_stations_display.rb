class AidStationsDisplay

  delegate :start_time, :course, :race, to: :event
  delegate :captain_name, :comms_chief_name, :comms_frequencies, to: :aid_station

  # initialize(event, params = {})
  # event is an ordinary event object
  # params is passed from the controller and may include
  # params[:search_param] (from user search input)
  # and params[:page] (for will_paginate)

  def initialize(event)
    @event = event
    @aid_stations = event.aid_stations.ordered.to_a[1..-1]
    @splits = event.splits.ordered.to_a
    @efforts = event.efforts.sorted_with_finish_status
    @ordered_split_ids = @splits.map(&:id)
    get_split_times
    set_aid_station_efforts
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
    event.course.name
  end

  def race_name
    event.race ? race.name : nil
  end

  # private

  attr_accessor :event_split_times
  attr_reader :event, :aid_stations, :splits, :efforts, :ordered_split_ids

  def get_split_times
    self.event_split_times = SplitTime.select(:id, :sub_split_bitkey, :split_id, :time_from_start, :data_status)
                                 .where(effort_id: efforts.map(&:id))
                                 .ordered
                                 .group_by(&:split_id)
  end

  def set_aid_station_efforts
    aid_stations.each do |aid_station|
      split = splits.find { |split| split.id = aid_station.split_id}
      split_times = event_split_times[split.id].group_by(&:effort_id)
      split_index = ordered_split_ids.index(split.id)
      efforts_dropped_at_station = efforts_dropped.select { |effort| effort.dropped_split_id == split.id }
      efforts_recorded_out = efforts_started
                                 .select { |effort| split_times[effort.id] ? split_times[effort.id]
                                                                                 .map(&:sub_split_bitkey)
                                                                                 .include?(SubSplit::OUT_BITKEY) : false }
      efforts_recorded_in = efforts_started
                                .select { |effort| split_times[effort.id] ? split_times[effort.id]
                                                                                .map(&:sub_split_bitkey)
                                                                                .include?(SubSplit::IN_BITKEY) : false }
      efforts_in_aid = efforts_recorded_in - efforts_recorded_out
      efforts_not_recorded = efforts_started - efforts_recorded_in - efforts_recorded_out
      efforts_passed_without_record = efforts_not_recorded
                                          .select { |effort| ordered_split_ids.index(effort.final_split_id) > split_index }
      efforts_expected = efforts_not_recorded - efforts_passed_without_record - efforts_dropped
      aid_station.efforts_dropped_at_station = efforts_dropped_at_station
      aid_station.efforts_recorded_out = efforts_recorded_out
      aid_station.efforts_in_aid = efforts_in_aid
      aid_station.efforts_passed_without_record = efforts_passed_without_record
      aid_station.efforts_expected = efforts_expected
    end
  end

  def efforts_started
    started_effort_ids = event_split_times[start_split_id].map(&:effort_id)
    efforts.select { |effort| started_effort_ids.include?(effort.id) }
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