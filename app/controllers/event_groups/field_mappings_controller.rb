module EventGroups
  # Persists per-Runsignup-question → Effort-attribute mappings configured via
  # the connection management UI. The same mapping is written to every
  # event-level Connection under the EventGroup (questions are race-level on
  # Runsignup, so a single configuration applies to all events).
  class FieldMappingsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_event_group
    before_action :set_service

    PERMITTED_DESTINATIONS = %w[comments emergency_contact emergency_phone].freeze

    def update
      authorize @event_group, :setup?

      mappings = normalized_mappings
      event_level_connections.each { |conn| conn.update!(field_mappings: mappings) }

      respond_to do |format|
        format.turbo_stream do
          render "event_groups/field_mappings/update",
                 locals: {
                   event_group_setup_presenter: EventGroupSetupPresenter.new(@event_group, view_context),
                   connect_service_presenter: ConnectServicePresenter.new(@event_group, @service, view_context),
                 }
        end
        format.html { redirect_to event_group_connect_service_path(@event_group, @service.identifier) }
      end
    end

    private

    def set_event_group
      @event_group = EventGroup.friendly.find(params[:event_group_id])
    end

    def set_service
      @service = ::Connectors::Service::BY_IDENTIFIER[params[:service_identifier]]
      raise ActiveRecord::RecordNotFound if @service.blank?
    end

    def normalized_mappings
      raw = params.fetch(:field_mappings, {})
      rows = raw.is_a?(ActionController::Parameters) ? raw.to_unsafe_h.values : raw

      rows.filter_map do |row|
        row = row.to_unsafe_h if row.respond_to?(:to_unsafe_h)
        destination = row["destination"].to_s.strip
        next if destination.blank?
        next unless PERMITTED_DESTINATIONS.include?(destination)

        question_id = Integer(row["source_question_id"], exception: false)
        next if question_id.nil?

        mapping = { "source_question_id" => question_id, "destination" => destination }
        suppress_when = row["suppress_when"].to_s.strip
        value_when_present = row["value_when_present"].to_s.strip
        mapping["suppress_when"] = suppress_when if suppress_when.present?
        mapping["value_when_present"] = value_when_present if value_when_present.present?
        mapping
      end
    end

    def event_level_connections
      @event_group.events.flat_map do |event|
        event.connections.from_service(@service.identifier).where(source_type: @service.resource_map[Event]).to_a
      end
    end
  end
end
