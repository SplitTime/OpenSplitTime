class EventGroupRosterPresenter < BasePresenter
  include PagyPresenter

  attr_reader :event_group, :pagy
  delegate :available_live, :concealed?, :multiple_events?, :name, :organization, :scheduled_start_time_local,
           :to_param, :unreconciled_efforts, to: :event_group

  def initialize(event_group, view_context)
    @event_group = event_group
    @view_context = view_context
    @params = view_context.prepared_params
  end

  def started_efforts
    @started_efforts ||= roster_efforts.select(&:started?)
  end

  def unstarted_efforts
    @unstarted_efforts ||= roster_efforts.reject(&:started?)
  end

  def ready_efforts
    @ready_efforts ||= roster_efforts.select(&:ready_to_start)
  end

  def ready_efforts_count
    ready_efforts.size
  end

  def roster_efforts
    @roster_efforts ||= event_group_efforts.roster_subquery
  end

  def roster_efforts_count
    @roster_efforts_count ||= roster_efforts.size
  end

  def filtered_roster_efforts
    return @filtered_roster_efforts if defined?(@filtered_roster_efforts)

    relation = event_group_efforts
      .from(roster_efforts, "efforts")
      .where(filter_hash)
      .search(search_text)
      .order(sort_hash.presence || {bib_number: :asc})

    relation = apply_checked_in_filter(relation)
    relation = apply_started_filter(relation)
    relation = apply_unreconciled_filter(relation)
    relation = apply_problem_filter(relation)

    @pagy, @filtered_roster_efforts = pagy_from_scope(relation, items: per_page, page: page)
    @filtered_roster_efforts
  end

  def filtered_roster_efforts_count
    @filtered_roster_efforts_count ||= filtered_roster_efforts.size
  end

  def filtered_roster_efforts_total_count
    @filtered_roster_efforts_total_count ||= pagy.count
  end

  def next_page_url
    view_context.url_for(request.params.merge(page: pagy.next)) if pagy.next
  end

  def events
    @events ||= event_group.events.select_with_params("").order(:scheduled_start_time).to_a
  end

  def event
    events.first
  end

  def display_style
    nil
  end

  def event_group_efforts
    event_group.efforts.includes(:event)
  end

  def check_in_button_param
    :check_in_group
  end

  private

  attr_reader :params, :view_context
  delegate :current_user, :request, to: :view_context, private: true

  def apply_checked_in_filter(relation)
    case params[:checked_in]&.to_boolean
    when true
      relation.where(checked_in: true)
    when false
      relation.where(checked_in: [false, nil])
    else
      relation
    end
  end

  def apply_started_filter(relation)
    case params[:started]&.to_boolean
    when true
      relation.where(started: true)
    when false
      relation.where(started: [false, nil])
    else
      relation
    end
  end

  def apply_unreconciled_filter(relation)
    case params[:unreconciled]&.to_boolean
    when true
      relation.where(person_id: nil)
    when false
      relation.where.not(person_id: nil)
    else
      relation
    end
  end

  def apply_problem_filter(relation)
    case params[:problem]&.to_boolean
    when true
      relation.invalid_status
    when false
      relation.valid_status
    else
      relation
    end
  end
end
