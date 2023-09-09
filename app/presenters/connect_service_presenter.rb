# frozen_string_literal: true

class ConnectServicePresenter < BasePresenter
  def initialize(event_group, service, view_context)
    @event_group = event_group
    @service = service
    @view_context = view_context
  end

  attr_reader :service

  def service_identifier
    service&.identifier
  end

  def syncable_source
    @syncable_source ||= event_group.syncable_sources.find_or_initialize_by(source_name: service_identifier) do |syncable_source|
      syncable_source.destination_name = "internal"
      syncable_source.source_type = source_type
    end
  end

  private

  attr_reader :event_group, :view_context

  def source_type
    service.resource_map[EventGroup]
  end
end
