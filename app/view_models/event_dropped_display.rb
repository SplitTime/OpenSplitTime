class EventDroppedDisplay
  attr_reader :event
  delegate :name, :start_time, :course, :organization, :simple?, :beacon_url, :available_live, to: :event

  # initialize(event, params = {})
  # event is an ordinary event object
  # params is passed from the controller and may include
  # params[:search] (from user search input)
  # and params[:page] (for will_paginate)

  def initialize(event, params)
    @event = event
    @params = params
  end

  def effort_rows
    sorted_efforts.map { |effort| EffortRow.new(effort: effort) }
  end

  def efforts_count
    started_efforts.size
  end

  def dropped_efforts_count
    dropped_efforts.size
  end

  private

  attr_reader :params

  def started_efforts
    @started_efforts ||= event.efforts.ranked_with_finish_status # This scope ignores efforts having no split_times.
  end

  def dropped_efforts
    @dropped_efforts ||= started_efforts.select(&:dropped?)
  end

  def sort_by
    params[:sort]
  end

  def sorted_efforts
    case sort_by
    when 'bib_asc'
      dropped_efforts.sort_by!(&:bib_number)
    when 'bib_desc'
      dropped_efforts.sort_by!(&:bib_number).reverse!
    when 'last'
      dropped_efforts.sort_by!(&:last_name)
    when 'first'
      dropped_efforts.sort_by!(&:first_name)
    when 'distance_asc'
      dropped_efforts.sort_by!(&:final_distance)
    when 'distance_desc'
      dropped_efforts.sort_by!(&:final_distance).reverse!
    when 'time_asc'
      dropped_efforts.sort_by!(&:final_time)
    else
      dropped_efforts.sort_by!(&:final_time).reverse!
    end
  end
end