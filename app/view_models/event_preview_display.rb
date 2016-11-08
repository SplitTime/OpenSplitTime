class EventPreviewDisplay

  attr_accessor :filtered_efforts
  attr_reader :event, :params, :effort_preview_rows
  delegate :name, :start_time, :course, :race, :simple?, :available_live, :beacon_url, to: :event

  # initialize(event, params = {})
  # event is an ordinary event object
  # params is passed from the controller and may include
  # params[:search] (from user search input)
  # and params[:page] (for will_paginate)

  def initialize(event, params = {})
    @event = event
    @params = params
    get_efforts(@params)
    @effort_preview_rows = []
    create_effort_preview_rows
  end

  def efforts_count
    event_efforts.count
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

  private

  attr_accessor :event_efforts, :started_efforts, :event_final_split_id, :indexed_participants

  def get_efforts(params)
    self.event_efforts = event.efforts
    self.filtered_efforts = event_efforts
                                .search(params[:search])
                                .order(:bib_number)
                                .paginate(page: params[:page], per_page: 25)
    self.indexed_participants = Participant.find(filtered_efforts.map(&:participant_id).compact).index_by(&:id)
  end

  def create_effort_preview_rows
    filtered_efforts.each do |effort|
      effort_preview_row = EffortPreviewRow.new(effort,
                                                participant: indexed_participants[effort.participant_id])
      effort_preview_rows << effort_preview_row
    end
  end

end