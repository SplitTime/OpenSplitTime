class EventWithEffortsPresenter < BasePresenter

  attr_reader :event
  delegate :id, :name, :course, :organization, :simple?, :beacon_url, :available_live,
           :finish_split, :start_split, :multiple_laps?, :to_param, to: :event

  def initialize(args)
    @event = args[:event]
    @params = args[:params] || {}
    post_initialize(args)
  end

  def post_initialize(args)
    ArgsValidator.validate(params: args, required: [:event, :params], exclusive: [:event, :params], class: self.class)
  end

  def ranked_effort_rows
    @ranked_effort_rows ||= filtered_ranked_efforts.map do |effort|
      participant = indexed_participants[effort.participant_id]
      effort.participant = participant if participant
      EffortRow.new(effort)
    end
  end

  def filtered_ranked_efforts
    @filtered_ranked_efforts ||=
        ranked_efforts
            .select { |effort| filtered_ids.include?(effort.id) }
            .paginate(page: started_page, per_page: per_page)
  end

  def event_efforts
    event.efforts
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

  def filtered_ranked_efforts_count
    filtered_ranked_efforts.total_entries
  end

  def course_name
    course.name
  end

  def organization_name
    organization&.name
  end

  def event_finished?
    event.finished?
  end

  def event_start_time
    @event_start_time ||= event.start_time
  end

  private

  attr_reader :params

  def ranked_efforts
    @ranked_efforts ||= event_efforts.ranked_with_finish_status(sort: sort_hash)
  end

  def unstarted_efforts
    @unstarted_efforts ||= event_efforts.where(id: unstarted_effort_ids).eager_load(:participant)
  end

  def unstarted_effort_ids
    @unstarted_effort_ids ||= event_efforts.ids - started_effort_ids
  end

  def started_effort_ids
    @started_effort_ids ||= ranked_efforts.map(&:id)
  end

  def filtered_ids
    @filtered_ids ||= event_efforts.where(filter_hash).search(search_text).ids.to_set
  end

  def indexed_participants
    @indexed_participants ||= Participant.where(id: participant_ids).index_by(&:id)
  end

  def participant_ids
    @participant_ids ||=
        (filtered_ranked_efforts.map(&:participant_id) + filtered_unstarted_efforts.map(&:participant_id)).compact
  end

  def started_page
    params[:started_page]
  end
end
