class EventEffortsDisplay
  include TimeFormats

  attr_reader :event
  delegate :name, :start_time, :course, :organization, :simple?, :beacon_url, :available_live,
           :finish_split, :start_split, :multiple_laps?, to: :event

  def initialize(args)
    @event = args[:event]
    @params = args[:params] || {}
  end

  def effort_rows
    @effort_rows ||= filtered_efforts.map do |effort|
      EffortRow.new(effort: effort,
                    participant: indexed_participants[effort.participant_id])
    end
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
end
