# frozen_string_literal: true

class ConnectServicePresenter < BasePresenter
  DEFAULT_CANDIDATE_SEPARATION_LIMIT = 7.days
  INTERNAL_SERVICES = [
    "internal_lottery",
  ]

  def initialize(event_group, service, view_context)
    @event_group = event_group
    @service = service
    @view_context = view_context
    @error_message = nil
  end

  attr_reader :event_group, :service

  def all_credentials_present?
    internal_service? || current_user.all_credentials_for?(service_identifier)
  end

  def error_message
    # Ensure that all_sources has been called so that @error_message is set.
    set_all_sources
    @error_message
  end

  def no_sources_found?
    all_sources.empty?
  end

  def no_sources_in_time_frame?
    event_group.events.flat_map { |event| sources_for_event(event) }.none?
  end

  def sources_available?
    !no_sources_found? && !no_sources_in_time_frame?
  end

  def event_group_name
    event_group.name
  end

  # This method returns an array of Structs that will respond (at minimum) to #id, #name, and #start_time.
  def sources_for_event(event)
    all_sources.reject do |source_struct|
      separation = (source_struct.start_time.in_time_zone(event_group.home_time_zone) - event.scheduled_start_time).abs
      separation > candidate_separation_limit
    end
  end

  def connections_with_blanks(event)
    sources_for_event(event).map do |source_struct|
      connection = event.connections.find_or_initialize_by(service_identifier: service_identifier, source_id: source_struct.id) do |connection|
        connection.source_type = event_source_type
      end

      connection.source_name = source_struct.name
      connection
    end
  end

  def service_identifier
    service&.identifier
  end

  def service_name
    service&.name
  end

  def successful_connection?
    all_credentials_present? && error_message.blank?
  end

  def connection
    @connection ||= event_group.connections.find_or_initialize_by(service_identifier: service_identifier) do |connection|
      connection.source_type = event_group_source_type
    end
  end

  private

  attr_reader :view_context
  delegate :current_user, to: :view_context, private: true
  delegate :organization, to: :event_group, private: true

  def all_sources
    # Ensure that set_all_sources has been called so that @all_sources is set.
    set_all_sources
    @all_sources
  end

  def set_all_sources
    return @all_sources if defined?(@all_sources)

    @all_sources = [] and return unless some_credentials_present?

    @all_sources = case service_identifier.to_sym
                  when :internal_lottery
                    all_internal_lotteries
                  when :rattlesnake_ramble
                    all_rattlesnake_ramble_events
                  when :runsignup
                    all_runsignup_events
                  else
                    []
                  end
  rescue ::Connectors::Errors::Base => error
    @error_message = error.message
  ensure
    @all_sources ||= []
  end

  def candidate_separation_limit
    case service_identifier.to_sym
    when :internal_lottery
      1.year
    else
      DEFAULT_CANDIDATE_SEPARATION_LIMIT
    end
  end

  def some_credentials_present?
    internal_service? || current_user.has_credentials_for?(service_identifier)
  end

  def internal_service?
    service_identifier.in?(INTERNAL_SERVICES)
  end

  def all_internal_lotteries
    organization.lotteries.order(:scheduled_start_date).to_a
  end

  def all_rattlesnake_ramble_events
    ::Connectors::RattlesnakeRamble::FetchRaceEditions.perform(user: current_user)
  end

  def all_runsignup_events
    if runsignup_race_id.blank?
      @error_message = "RunSignup Race ID is required"
      return []
    end

    ::Connectors::Runsignup::FetchRaceEvents.perform(race_id: runsignup_race_id, user: current_user)
  end

  def runsignup_race_id
    event_group.connections.from_service(:runsignup).where(source_type: "Race").first&.source_id
  end

  def event_group_source_type
    service.resource_map[EventGroup]
  end

  def event_source_type
    service.resource_map[Event]
  end
end
