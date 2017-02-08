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
      EffortRow.new(effort,
                    overall_place: effort.overall_place,
                    gender_place: effort.gender_place,
                    finish_status: finish_status(effort),
                    run_status: run_status(effort),
                    day_and_time: start_time + effort.start_offset + effort.final_time,
                    participant: indexed_participants[effort.participant_id])
    end
  end

  def filtered_efforts
    @filtered_efforts ||= event_efforts
                              .search(params[:search])
                              .sorted_with_finish_status
                              .paginate(page: params[:page], per_page: params[:per_page] || 25)
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

  def course_name
    course.name
  end

  def organization_name
    organization.try(:name)
  end

  def to_ultrasignup_csv
    return 'One or more efforts is in progress. Set drops before exporting.' unless event_finished?
    CSV.generate do |csv|
      csv << %w(place time first last age gender city state dob bib status)
      effort_rows.each do |row|
        csv << [row.overall_place,
                row.finish_time && time_format_hhmmss(row.finish_time),
                row.first_name,
                row.last_name,
                row.age,
                row.gender,
                row.city,
                row.state_code,
                row.birthdate,
                row.bib_number,
                row.ultrasignup_finish_status]
      end
    end
  end

  private

  attr_reader :params

  def event_finished?
    event.finished?
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

  def started_effort_ids
    @started_effort_ids ||= event_efforts.started.ids
  end

  def indexed_participants
    @indexed_participants ||= Participant.find(filtered_efforts.map(&:participant_id).compact).index_by(&:id)
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