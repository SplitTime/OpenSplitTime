class EventWithEffortsPresenter < BasePresenter
  DEFAULT_ORDER_CRITERIA = { overall_rank: :asc, bib_number: :asc }

  attr_reader :event

  delegate :course_groups, to: :course
  delegate :id, :name, :course, :course_id, :simple?, :beacon_url, :home_time_zone, :finish_split,
           :start_split, :multiple_laps?, :to_param, :created_by, :new_record?, :event_group,
           :ordered_events_within_group, :scheduled_start_time_local, :efforts_count, :notice_text, :notice_text?, to: :event
  delegate :available_live, :available_live?, :concealed, :concealed?, :organization, :monitor_pacers?,
           :multiple_events?, to: :event_group

  def initialize(args)
    @event = args[:event]
    @params = args[:params] || {}
    @current_user = args[:current_user]
    post_initialize(args)
  end

  def post_initialize(args)
    ArgsValidator.validate(params: args, required: [:event, :params], exclusive: [:event, :params, :current_user], class: self.class)
  end

  def ranked_effort_rows
    @ranked_effort_rows ||= filtered_ranked_efforts.map do |effort|
      effort.person = indexed_people[effort.person_id]
      EffortRow.new(effort)
    end
  end

  def filtered_ranked_efforts
    @filtered_ranked_efforts ||=
      ranked_efforts
        .where(filter_hash)
        .search(search_text)
        .paginate(page: page, per_page: per_page)
  end

  def event_efforts
    event.efforts
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
    @event_finished ||= ranked_efforts.none?(&:in_progress?)
  end

  def authorized_to_edit?
    current_user&.authorized_to_edit?(event) || false
  end

  private

  attr_reader :params, :current_user

  def ranked_efforts
    @ranked_efforts ||= event_efforts.ranking_subquery.finish_info_subquery.order(order_criteria)
  end

  def order_criteria
    sort_hash.presence || DEFAULT_ORDER_CRITERIA
  end

  def filtered_ids
    @filtered_ids ||= event_efforts.where(filter_hash).search(search_text).ids.to_set
  end

  def indexed_people
    @indexed_people ||= Person.where(id: person_ids).index_by(&:id)
  end

  def person_ids
    @person_ids ||= filtered_ranked_efforts.map(&:person_id).compact
  end
end
