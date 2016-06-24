class AidStationDetail

  attr_reader :aid_station
  attr_accessor :efforts_dropped_here, :efforts_recorded_in, :efforts_recorded_out,
                :efforts_in_aid, :efforts_missed, :efforts_expected
  delegate :course, :race, to: :event
  delegate :event, :split, :open_time, :close_time, :captain_name, :comms_chief_name,
           :comms_frequencies, :current_issues, to: :aid_station
  delegate :expected_day_and_time, to: :progress_event

  def initialize(aid_station, progress_event = nil, split_times = nil)
    @aid_station = aid_station
    @progress_event = progress_event || ProgressEvent.new(event)
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

  def bitkey_hash_in
    {split_id => SubSplit::IN_BITKEY}
  end

  def expected_progress_efforts
    efforts_expected_ids = efforts_expected.map(&:id)
    progress_efforts.select { |progress_effort| efforts_expected_ids.include?(progress_effort.id) }
  end

  private

  attr_reader :progress_event, :split_times
  delegate :ordered_split_ids, :efforts_started, :efforts_dropped, :efforts_finished,
           :efforts_in_progress, :progress_efforts, to: :progress_event

  def set_split_times
    progress_event.split_times.group_by(&:split_id)[aid_station.split_id].group_by(&:effort_id)
  end

  def set_efforts
    efforts_dropped_here = efforts_dropped.select { |effort| effort.dropped_split_id == split_id }
    efforts_recorded_in = efforts_started
                              .select { |effort| split_times[effort.id] ? split_times[effort.id]
                                                                              .map(&:sub_split_bitkey)
                                                                              .include?(SubSplit::IN_BITKEY) : false }
    efforts_recorded_out = efforts_started
                               .select { |effort| split_times[effort.id] ? split_times[effort.id]
                                                                               .map(&:sub_split_bitkey)
                                                                               .include?(SubSplit::OUT_BITKEY) : false }
    efforts_in_aid = efforts_recorded_in - efforts_recorded_out
    efforts_not_recorded = efforts_started - efforts_recorded_in - efforts_recorded_out
    efforts_missed = efforts_not_recorded
                         .select { |effort| ordered_split_ids.index(effort.final_split_id) > ordered_split_ids.index(split_id) }
    efforts_expected = efforts_not_recorded - efforts_missed - efforts_dropped
    self.efforts_dropped_here = efforts_dropped_here
    self.efforts_recorded_in = efforts_recorded_in
    self.efforts_recorded_out = efforts_recorded_out
    self.efforts_in_aid = efforts_in_aid
    self.efforts_missed = efforts_missed
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

  def efforts_expected_count
    efforts_expected.count
  end

end