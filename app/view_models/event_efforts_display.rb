class EventEffortsDisplay
  include TimeFormats

  attr_reader :event
  delegate :name, :start_time, :course, :organization, :simple?, :beacon_url, :available_live,
           :finish_split, :start_split, to: :event

  # initialize(event, params = {})
  # event is an ordinary event object
  # params is passed from the controller and may include
  # params[:search] (from user search input)
  # and params[:page] (for will_paginate)

  def initialize(event, params = {})
    @event = event
    @params = params
  end

  def effort_rows
    @effort_rows ||= filtered_efforts.map do |effort|
      EffortRow.new(effort: effort,
                    finish_status: finish_status(effort),
                    run_status: run_status(effort),
                    day_and_time: start_time + effort.start_offset + effort.final_time,
                    participant: indexed_participants[effort.participant_id])
    end
  end

  def effort_preview_rows
    @effort_preview_rows ||= unstarted_efforts.map { |effort| EffortPreviewRow.new(effort) }
  end

  def filtered_efforts
    @filtered_efforts ||= event_efforts
                              .search(params[:search])
                              .ranked_with_finish_status
                              .paginate(page: params[:started_page], per_page: params[:per_page] || 25)
  end

  def unstarted_efforts
    @unstarted_efforts ||= event_efforts
                               .eager_load(:participant)
                               .search(params[:search])
                               .where(id: unstarted_effort_ids)
                               .order(:last_name)
                               .paginate(page: params[:unstarted_page], per_page: params[:per_page] || 25)
  end

  def efforts_count
    event_efforts.size
  end

  def started_efforts_count
    started_effort_ids.size
  end

  def unstarted_efforts_count
    efforts_count - started_efforts_count
  end

  def filtered_efforts_count
    filtered_efforts.total_entries
  end

  def unstarted_filtered_efforts_count
    unstarted_efforts.total_entries
  end

  def course_name
    course.name
  end

  def organization_name
    organization.try(:name)
  end

  def event_finished?
    event.finished?
  end

  private

  attr_reader :params

  def indexed_participants
    @indexed_participants ||= Participant.where(id: participant_ids).index_by(&:id)
  end

  def participant_ids
    @participant_ids ||= (filtered_efforts.map(&:participant_id) + unstarted_efforts.map(&:participant_id)).compact
  end

  def event_final_split_id
    @event_final_split_id ||= finish_split.try(:id)
  end

  def event_start_split_id
    @event_start_split_id ||= start_split.try(:id)
  end

  def event_efforts
    event.efforts
  end

  def unstarted_effort_ids
    @unstarted_effort_ids ||= event_efforts.map(&:id) - started_effort_ids
  end

  def started_effort_ids
    @started_effort_ids ||= event_efforts.started.ids
  end

  def finish_status(effort)
    return effort.final_time if effort.finished?
    return 'DNS' unless started_effort_ids.include?(effort.id)
    return "Dropped at #{effort.final_split_name}" if effort.dropped?
    'In progress'
  end

  def run_status(effort)
    return 'DNS' unless started_effort_ids.include?(effort.id)
    return 'Started' if effort.final_split_id == event_start_split_id
    return "Dropped at #{effort.final_split_name}" if effort.dropped?
    return 'Finished' if effort.finished?
    "Reported through #{effort.final_split_name}"
  end
end