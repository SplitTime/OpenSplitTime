class EventDroppedDisplay

  attr_accessor :dropped_efforts
  attr_reader :event, :effort_rows
  delegate :name, :start_time, :course, :race, :simple?, :beacon_url, :available_live, to: :event

  # initialize(event, params = {})
  # event is an ordinary event object
  # params is passed from the controller and may include
  # params[:search] (from user search input)
  # and params[:page] (for will_paginate)

  def initialize(event)
    @event = event
    get_efforts
    @effort_rows = []
    create_effort_rows
  end

  def efforts_count
    event_efforts ? event_efforts.count : 0
  end

  def dropped_efforts_count
    dropped_efforts ? dropped_efforts.count : 0
  end

  # private

  attr_accessor :event_efforts, :started_efforts, :event_final_split_id

  def get_efforts
    self.event_efforts = event.efforts
    self.started_efforts = event_efforts.sorted_with_finish_status # This method ignores efforts having no split_times.
    self.dropped_efforts = started_efforts.select { |effort| effort.dropped_split_id.present? }
  end

  def create_effort_rows
    dropped_efforts.each do |effort|
      effort_row = EffortRow.new(effort,
                                 run_status: run_status(effort),
                                 day_and_time: start_time + effort.start_offset + effort.time_from_start)
      effort_rows << effort_row
    end
  end

  def run_status(effort)
    return "Dropped at #{effort.final_split_name}" if effort.dropped_split_id
    "Reported through #{effort.final_split_name}"
  end

end