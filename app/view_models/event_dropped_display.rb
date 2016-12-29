class EventDroppedDisplay

  attr_accessor :dropped_efforts
  attr_reader :event, :effort_rows
  delegate :name, :start_time, :course, :race, :simple?, :beacon_url, :available_live, to: :event

  # initialize(event, params = {})
  # event is an ordinary event object
  # params is passed from the controller and may include
  # params[:search] (from user search input)
  # and params[:page] (for will_paginate)

  def initialize(event, params)
    @event = event
    get_efforts
    sort_efforts(params[:sort])
    @effort_rows = []
    create_effort_rows
  end

  def efforts_count
    event_efforts ? event_efforts.count : 0
  end

  def dropped_efforts_count
    dropped_efforts ? dropped_efforts.count : 0
  end

  private

  attr_accessor :event_efforts, :started_efforts, :event_final_split_id

  def get_efforts
    self.event_efforts = event.efforts
    self.started_efforts = event_efforts.sorted_with_finish_status # This method ignores efforts having no split_times.
    self.dropped_efforts = started_efforts.select { |effort| effort.dropped_split_id.present? }
  end

  def sort_efforts(sort_by)
    dropped_efforts.sort_by!(&:bib_number) if sort_by == 'bib_asc'
    dropped_efforts.sort_by!(&:bib_number).reverse! if sort_by == 'bib_desc'
    dropped_efforts.sort_by!(&:last_name) if sort_by == 'last'
    dropped_efforts.sort_by!(&:first_name) if sort_by == 'first'
    dropped_efforts.sort_by!(&:distance_from_start) if sort_by == 'distance_asc'
    dropped_efforts.sort_by!(&:distance_from_start).reverse! if sort_by == 'distance_desc'
    dropped_efforts.sort_by!(&:time_from_start) if sort_by == 'time_asc'
    dropped_efforts.sort_by!(&:time_from_start).reverse! if sort_by == 'time_desc'
  end

  def create_effort_rows
    dropped_efforts.each do |effort|
      effort_row = EffortRow.new(effort,
                                 dropped_split_name: dropped_split_name(effort),
                                 day_and_time: start_time + effort.start_offset + effort.time_from_start)
      effort_rows << effort_row
    end
  end

  def dropped_split_name(effort)
     effort.final_split_name
  end

end