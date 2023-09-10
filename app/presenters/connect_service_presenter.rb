# frozen_string_literal: true

class ConnectServicePresenter < BasePresenter
  CANDIDATE_SEPARATION_LIMIT = 7.days

  def initialize(event_group, service, view_context)
    @event_group = event_group
    @service = service
    @view_context = view_context
  end

  attr_reader :event_group, :service

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

  attr_reader :view_context
  delegate :current_user, to: :view_context, private: true

  def all_events
    case service_identifier.to_sym
    when :runsignup
      all_runsignup_events
    when :rattlesnake_ramble
      all_rattlesnake_ramble_events
    else
      []
    end
  end

  def all_rattlesnake_ramble_events
    return [] unless current_user.has_credentials_for?(:rattlesnake_ramble)

    @all_rattlesnake_ramble_events ||= ::Connectors::RattlesnakeRamble::FetchRaceEditions.perform(user: current_user)
  end

  def all_runsignup_events
    return [] unless runsignup_race_id.present? && current_user.has_credentials_for?(:runsignup)

    @all_runsignup_events ||= ::Connectors::Runsignup::FetchRaceEvents.perform(race_id: runsignup_race_id, user: current_user)
  end

  def runsignup_race_id
    return @runsignup_race_id if defined?(@runsignup_race_id)

    @runsignup_race_id = event_group.connections.from_service(:runsignup).where(source_type: "Race").first&.source_id
  end

  def source_type
    service.resource_map[EventGroup]
  end
end
