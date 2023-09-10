# frozen_string_literal: true

class EventGroupSetupPresenter < BasePresenter
  CANDIDATE_SEPARATION_LIMIT = 7.days

  attr_reader :event_group
  delegate :available_live?,
           :connections,
           :concealed?,
           :first_event,
           :home_time_zone,
           :multiple_events?,
           :name,
           :organization,
           :partners,
           :to_param,
           :unreconciled_efforts,
           to: :event_group

  def initialize(event_group, view_context)
    @event_group = event_group
    @view_context = view_context
    @params = view_context.prepared_params
  end

  def authorized_fully?
    @authorized_fully ||= current_user.authorized_fully?(event_group)
  end

  def available_courses
    organization.courses
  end

  def candidate_events
    return [] unless events.present?

    (organization.events.select_with_params("").order(scheduled_start_time: :desc) - events)
      .select { |event| (event.scheduled_start_time - events.first.scheduled_start_time).abs < CANDIDATE_SEPARATION_LIMIT }
  end

  def courses
    events.map(&:course).uniq
  end

  def event_group_efforts
    event_group.efforts.includes(:event)
  end

  def event_group_efforts_count
    @event_group_efforts_count ||= event_group_efforts.count
  end

  def filtered_efforts
    @filtered_efforts ||= event_group_efforts
                            .where(filter_hash)
                            .search(search_text)
                            .order(sort_hash.presence || { bib_number: :asc })
                            .paginate(page: page, per_page: per_page)
  end

  def filtered_efforts_count
    @filtered_efforts_count ||= filtered_efforts.size
  end

  def event_group_name
    event_group.name
  end

  def event_group_names
    events.map(&:name).to_sentence(two_words_connector: " and ", last_word_connector: ", and ")
  end

  def events
    @events ||= event_group.events.order(:scheduled_start_time)
  end

  def no_persisted_events?
    @persisted_events ||= events.none?(&:persisted?)
  end

  def next_page_url
    view_context.url_for(request.params.merge(page: page + 1)) if filtered_efforts_count == per_page
  end

  def organization_name
    organization.name
  end

  def available_connection_services
    Connectors::Service.all
  end

  def existing_connection_services
    existing_service_identifiers.map { |service_identifier| Connectors::Service::BY_IDENTIFIER[service_identifier] }
  end

  def existing_service_identifiers
    @existing_service_identifiers ||=
      Connection.where(destination: event_group).or(Connection.where(destination: event_group.events)).distinct.pluck(:service_identifier)
  end

  def service_identifier
    params[:service_identifier]
  end

  def active_widget_card
    if controller_name == "event_groups" && action_name.in?(%w(setup new))
      :overview
    elsif action_name == "setup_summary"
      :status
    elsif controller_name == "events"
      :events_and_courses
    else
      :entrants
    end
  end

  def status
    available_live? ? "live" : "not_live"
  end

  private

  attr_reader :params, :view_context
  delegate :current_user, :request, to: :view_context, private: true
end
