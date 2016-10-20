class EventEffortsDisplay

  attr_accessor :filtered_efforts
  attr_reader :event, :effort_rows
  delegate :name, :start_time, :course, :race, :simple?, :beacon_url, :available_live,
           :finish_split, :start_split, to: :event

  # initialize(event, params = {})
  # event is an ordinary event object
  # params is passed from the controller and may include
  # params[:search] (from user search input)
  # and params[:page] (for will_paginate)

  def initialize(event, params = {})
    @event = event
    @event_final_split_id = finish_split.id if finish_split
    @event_start_split_id = start_split.id if start_split
    get_efforts(params)
    @effort_rows = []
    create_effort_rows
  end

  def efforts_count
    event_efforts.count
  end

  def started_efforts_count
    started_efforts.count
  end

  def unstarted_efforts_count
    efforts_count - started_efforts_count
  end

  def filtered_efforts_count
    filtered_efforts.total_entries
  end

  def course_name
    course.name
  end

  def race_name
    race ? race.name : nil
  end

  def beacon_button_text
    return nil unless beacon_url.present?
    return 'SPOT Page' if beacon_url.include?('findmespot.com')
    return 'FasterTracks' if beacon_url.include?('fastertracks.com')
    return 'SPOT via TrackLeaders' if beacon_url.include?('trackleaders.com')
    'Event Locator Beacon'
  end

  private

  attr_accessor :event_efforts, :started_efforts, :event_final_split_id,
                :event_start_split_id, :indexed_participants

  def get_efforts(params)
    self.event_efforts = event.efforts
    self.started_efforts = event_efforts.sorted_with_finish_status # This method ignores efforts having no split_times.
    self.filtered_efforts = event_efforts
                                .search(params[:search])
                                .sorted_with_finish_status
                                .paginate(page: params[:page], per_page: params[:per_page] || 25)
    self.indexed_participants = Participant.find(filtered_efforts.map(&:participant_id)).index_by(&:id)
  end

  def create_effort_rows
    filtered_efforts.each do |effort|
      effort_row = EffortRow.new(effort,
                                 overall_place: overall_place(effort),
                                 gender_place: gender_place(effort),
                                 finish_status: finish_status(effort),
                                 run_status: run_status(effort),
                                 day_and_time: start_time + effort.start_offset + effort.time_from_start,
                                 participant: indexed_participants[effort.participant_id])
      effort_rows << effort_row
    end
  end

  def finish_status(effort)
    return effort.time_from_start if effort.final_split_id == event_final_split_id
    return "DNS" unless started_efforts.include?(effort)
    return "Dropped at #{effort.final_split_name}" if effort.dropped_split_id
    "In progress"
  end

  def run_status(effort)
    return "DNS" unless started_efforts.include?(effort)
    return "Started" if effort.final_split_id == event_start_split_id
    return "Dropped at #{effort.final_split_name}" if effort.dropped_split_id
    return "Finished" if effort.final_split_id == event_final_split_id
    "Reported through #{effort.final_split_name}"
  end

  def overall_place(effort)
    sorted_effort_ids.index(effort.id) + 1
  end

  def gender_place(effort)
    sorted_genders[0...overall_place(effort)].count(effort.gender)
  end

  def sorted_effort_ids
    started_efforts.map(&:id)
  end

  def sorted_genders
    started_efforts.map(&:gender)
  end

end