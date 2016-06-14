class AidStationDetail

  delegate :course, :race, to: :event
  delegate :event, :split, :open_time, :close_time, :captain_name, :comms_chief_name,
           :comms_frequencies, :current_issues, to: :aid_station

  # initialize(event, params = {})
  # event is an ordinary event object
  # params is passed from the controller and may include
  # params[:search_param] (from user search input)
  # and params[:page] (for will_paginate)

  def initialize(aid_station, efforts_started = nil, split_times = nil, ordered_split_ids = nil)
    @aid_station = aid_station
    @ordered_split_ids = ordered_split_ids || set_ordered_split_ids
    @efforts_started = efforts_started || set_efforts_started
    @split_times = split_times || set_split_times
    set_efforts
    set_open_status if aid_station.status.nil?
  end

  def efforts_started_count
    efforts_started.count
  end

  def split_name
    split.base_name
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

  # private

  attr_accessor :efforts_dropped_at_station, :efforts_recorded_out,
                :efforts_in_aid, :efforts_passed_without_record, :efforts_expected
  attr_reader :efforts_started, :split_times, :ordered_split_ids, :aid_station

  def set_ordered_split_ids
    event.ordered_split_ids
  end

  def set_efforts_started
    event_efforts = event.efforts.sorted_with_finish_status
    event_split_times = SplitTime.select(:id, :sub_split_bitkey, :split_id, :time_from_start, :data_status)
                            .where(effort_id: event_efforts.map(&:id))
                            .ordered
                            .group_by(&:split_id)
    started_effort_ids = event_split_times[start_split_id].map(&:effort_id)
    event_efforts.select { |effort| started_effort_ids.include?(effort.id) }
  end

  def set_split_times
    event.split_times.where(split_id: aid_station.split_id).group_by(&:effort_id)
  end

  def set_efforts
    split_index = ordered_split_ids.index(split_id)
    efforts_dropped_at_station = efforts_dropped.select { |effort| effort.dropped_split_id == split_id }
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
    self.efforts_dropped_at_station = efforts_dropped_at_station
    self.efforts_recorded_out = efforts_recorded_out
    self.efforts_in_aid = efforts_in_aid
    self.efforts_passed_without_record = efforts_passed_without_record
    self.efforts_expected = efforts_expected
  end

  def set_open_status
    if efforts_started_count == 0
      status = 'pre_open'
    elsif efforts_expected_count == 0
      status = 'closed'
    else
      status = 'open'
    end
    self.aid_station.update(status: status)
  end

  def split_id
    aid_station.split_id
  end

  def start_split_id
    ordered_split_ids.first
  end

  def efforts_dropped
    efforts_started.select { |effort| effort.dropped_split_id.present? }
  end

  def efforts_expected_count
    efforts_expected.count
  end

end