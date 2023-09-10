# frozen_string_literal: true

class ConnectServicePresenter < BasePresenter
  CANDIDATE_SEPARATION_LIMIT = 7.days

  def initialize(event_group, service, view_context)
    @event_group = event_group
    @service = service
    @view_context = view_context
    @error_message = nil
    set_all_events
  end

  attr_reader :event_group, :service, :error_message

  def all_credentials_present?
    current_user.all_credentials_for?(service_identifier)
  end

  def connection_invalid?
    !all_credentials_present? || error_message.present?
  end

  def no_events_found?
    all_events.empty?
  end

  def no_events_in_time_frame?
    event_group.events.flat_map { |event| external_events(event) }.none?
  end

  def event_group_name
    event_group.name
  end

  def external_events(event)
    all_events.reject do |event_struct|
      (event_struct.start_time.in_time_zone(event_group.home_time_zone) - event.scheduled_start_time).abs > CANDIDATE_SEPARATION_LIMIT
    end
  end

  def service_identifier
    service&.identifier
  end

  def service_name
    service&.name
  end

  def connection
    @connection ||= event_group.connections.find_or_initialize_by(service_identifier: service_identifier) do |connection|
      connection.source_type = source_type
    end
  end

  private

  attr_reader :view_context, :all_events
  delegate :current_user, to: :view_context, private: true

  def set_all_events
    @all_events = [] and return unless some_credentials_present?

    @all_events = case service_identifier.to_sym
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
    @all_events ||= []
  end

  def some_credentials_present?
    current_user.has_credentials_for?(service_identifier)
  end

  def all_rattlesnake_ramble_events
    ::Connectors::RattlesnakeRamble::FetchRaceEditions.perform(user: current_user)
  end

  def all_runsignup_events
    race_id = event_group.connections.from_service(:runsignup).where(source_type: "Race").first&.source_id
    ::Connectors::Runsignup::FetchRaceEvents.perform(race_id: race_id, user: current_user)
  end

  def source_type
    service.resource_map[EventGroup]
  end
end
