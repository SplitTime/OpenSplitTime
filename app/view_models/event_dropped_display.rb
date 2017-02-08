class EventDroppedDisplay

  attr_accessor :dropped_efforts
  attr_reader :event, :effort_rows
  delegate :name, :start_time, :course, :organization, :simple?, :beacon_url, :available_live, to: :event

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
    event_efforts.size
  end

  def dropped_efforts_count
    dropped_efforts.size
  end

  private

  attr_accessor :event_efforts, :started_efforts, :event_final_split_id

  def get_efforts
    self.event_efforts = event.efforts
    self.started_efforts = event_efforts.sorted_with_finish_status # This method ignores efforts having no split_times.
    self.dropped_efforts = started_efforts.select(&:dropped?)
  end

  def sort_efforts(sort_by)
    dropped_efforts.sort_by!(&:bib_number) if sort_by == 'bib_asc'
    dropped_efforts.sort_by!(&:bib_number).reverse! if sort_by == 'bib_desc'
    dropped_efforts.sort_by!(&:last_name) if sort_by == 'last'
    dropped_efforts.sort_by!(&:first_name) if sort_by == 'first'
    dropped_efforts.sort_by!(&:final_distance) if sort_by == 'distance_asc'
    dropped_efforts.sort_by!(&:final_distance).reverse! if sort_by == 'distance_desc'
    dropped_efforts.sort_by!(&:final_time) if sort_by == 'time_asc'
    dropped_efforts.sort_by!(&:final_time).reverse! if sort_by == 'time_desc'
  end

  def create_effort_rows
    dropped_efforts.each do |effort|
      effort_row = EffortRow.new(effort,
                                 dropped_split_name: effort.final_split_name,
                                 day_and_time: start_time + effort.start_offset + effort.final_time)
      effort_rows << effort_row
    end
  end
end