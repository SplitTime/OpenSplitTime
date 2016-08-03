class AidStationDetail

  attr_reader :aid_station
  attr_accessor :efforts_dropped_here, :efforts_recorded_in, :efforts_recorded_out,
                :efforts_in_aid, :efforts_missed, :efforts_expected
  delegate :course, :race, to: :event
  delegate :event, :split, :open_time, :close_time, :status, :captain_name, :comms_crew_names,
           :comms_frequencies, :current_issues, to: :aid_station
  delegate :expected_day_and_time, :prior_valid_display_data, :next_valid_display_data, to: :live_event

  def initialize(aid_station, live_event = nil, split_times = nil)
    @aid_station = aid_station
    @live_event = live_event || LiveEvent.new(event)
    @split_times = split_times || set_split_times
    set_efforts
    set_status if aid_station.status.nil?
  end

  def efforts_started_count
    efforts_started ? efforts_started.count : 0
  end

  def efforts_expected_count
    efforts_expected ? efforts_expected.count : 0
  end

  def efforts_expected_ids
    efforts_expected ? efforts_expected.map(&:id) : []
  end

  def efforts_expected_table_title
    "#{persons(efforts_expected_count)} #{is_are(efforts_expected_count)} expected at #{aid_station.split_name}"
  end

  def efforts_dropped_here_count
    efforts_dropped_here ? efforts_dropped_here.count : 0
  end

  def efforts_dropped_here_ids
    efforts_dropped_here ? efforts_dropped_here.map(&:id) : []
  end

  def efforts_dropped_here_table_title
    "#{persons(efforts_dropped_here_count)} #{has_have(efforts_dropped_here_count)} dropped at #{aid_station.split_name}"
  end

  def efforts_missed_count
    efforts_missed ? efforts_missed.count : 0
  end

  def efforts_missed_ids
    efforts_missed ? efforts_missed.map(&:id) : []
  end

  def efforts_missed_table_title
    "#{persons(efforts_missed_count)} #{was_were(efforts_missed_count)} missed at #{aid_station.split_name} (not recorded here but recorded at a later aid station)"
  end

  def efforts_recorded_in_count
    efforts_recorded_in ? efforts_recorded_in.count : 0
  end

  def efforts_recorded_in_ids
    efforts_recorded_in ? efforts_recorded_in.map(&:id) : []
  end

  def efforts_recorded_in_table_title
    "#{persons(efforts_recorded_in_count)} #{was_were(efforts_recorded_in_count)} recorded in at #{aid_station.split_name}"
  end

  def efforts_recorded_out_count
    efforts_recorded_out ? efforts_recorded_out.count : 0
  end

  def efforts_recorded_out_ids
    efforts_recorded_out ? efforts_recorded_out.map(&:id) : []
  end

  def efforts_recorded_out_table_title
    "#{persons(efforts_recorded_out_count)} #{was_were(efforts_recorded_out_count)} recorded in at #{aid_station.split_name}"
  end

  def efforts_in_aid_count
    efforts_in_aid ? efforts_in_aid.count : 0
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

  def split_id
    aid_station.split_id
  end

  def bitkey_hash_in
    {split_id => SubSplit::IN_BITKEY}
  end

  def bitkey_hash_out
    {split_id => SubSplit::OUT_BITKEY}
  end

  def recorded_in_day_and_time(live_effort)
    split_time_in = split_times[live_effort.id].index_by(&:bitkey_hash)[bitkey_hash_in]
    split_time_in ? live_effort.start_time + split_time_in.time_from_start : nil
  end

  def recorded_out_day_and_time(live_effort)
    split_time_out = split_times[live_effort.id].index_by(&:bitkey_hash)[bitkey_hash_out]
    split_time_out ? live_effort.start_time + split_time_out.time_from_start : nil
  end

  def expected_live_efforts
    expected_ids = efforts_expected.map(&:id)
    live_efforts.select { |live_effort| expected_ids.include?(live_effort.id) }
  end

  def recorded_in_live_efforts
    recorded_in_ids = efforts_recorded_in.map(&:id)
    live_efforts.select { |live_effort| recorded_in_ids.include?(live_effort.id) }
  end

  def recorded_out_live_efforts
    recorded_out_ids = efforts_recorded_out.map(&:id)
    live_efforts.select { |live_effort| recorded_out_ids.include?(live_effort.id) }
  end

  def in_aid_live_efforts
    in_aid_ids = efforts_in_aid.map(&:id)
    live_efforts.select { |live_effort| in_aid_ids.include?(live_effort.id) }
  end

  def missed_live_efforts
    missed_ids = efforts_missed.map(&:id)
    live_efforts.select { |live_effort| missed_ids.include?(live_effort.id) }
  end

  def dropped_here_live_efforts
    dropped_ids = efforts_dropped_here.map(&:id)
    live_efforts.select { |live_effort| dropped_ids.include?(live_effort.id) }
  end

  private

  attr_reader :live_event, :split_times
  delegate :ordered_split_ids, :efforts_started, :efforts_dropped, :efforts_finished,
           :efforts_in_progress, :live_efforts, to: :live_event

  def set_split_times
    return nil unless live_event.split_times
    return nil unless live_event.split_times.group_by(&:split_id)[aid_station.split_id]
    live_event.split_times.group_by(&:split_id)[aid_station.split_id].group_by(&:effort_id)
  end

  def set_efforts
    efforts_dropped_here = efforts_dropped.select { |effort| effort.dropped_split_id == split_id }
    if split_times
      efforts_recorded_in = efforts_started
                                .select { |effort| split_times[effort.id] ? split_times[effort.id]
                                                                                .map(&:sub_split_bitkey)
                                                                                .include?(SubSplit::IN_BITKEY) : false }
      efforts_recorded_out = efforts_started
                                 .select { |effort| split_times[effort.id] ? split_times[effort.id]
                                                                                 .map(&:sub_split_bitkey)
                                                                                 .include?(SubSplit::OUT_BITKEY) : false }
    else
      efforts_recorded_in = efforts_recorded_out = []
    end
    efforts_in_aid = efforts_recorded_in - efforts_recorded_out
    efforts_not_recorded = efforts_started - efforts_recorded_in - efforts_recorded_out
    efforts_missed = efforts_not_recorded
                         .select { |effort| ordered_split_ids.index(effort.final_split_id) > ordered_split_ids.index(split_id) }
    efforts_expected = efforts_not_recorded - efforts_missed - efforts_dropped
    self.efforts_recorded_in = efforts_recorded_in
    self.efforts_recorded_out = efforts_recorded_out
    self.efforts_in_aid = efforts_in_aid
    self.efforts_missed = efforts_missed
    self.efforts_dropped_here = efforts_dropped_here
    self.efforts_expected = efforts_expected
  end

  def set_status
    if efforts_started_count == 0
      status = 'pre_open'
    elsif efforts_expected_count == 0
      status = 'closed'
    else
      status = 'open'
    end
    self.aid_station.update(status: status)
  end

  def start_split_id
    ordered_split_ids.first
  end

  def persons(number)
    number == 1 ? "#{number} person" : "#{number} people"
  end

  def was_were(number)
    number == 1 ? 'was' : 'were'
  end

  def is_are(number)
    number == 1 ? 'is' : 'are'
  end

  def has_have(number)
    number == 1 ? 'has' : 'have'
  end

end