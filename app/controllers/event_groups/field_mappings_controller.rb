module EventGroups
  # Persists Runsignup-question → Effort-attribute mappings configured via the
  # connection management UI. The mapping is stored on the EventGroup-level
  # Race Connection (questions are race-level on Runsignup, so one mapping per
  # race; the Race Connection always exists once the user has entered a race
  # ID, even before they've toggled on the per-event connection switches).
  class FieldMappingsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_event_group
    before_action :set_service

    PERMITTED_DESTINATIONS = %w[comments emergency_contact emergency_phone].freeze

    def update
      authorize @event_group, :setup?

      conn = race_connection
      raise ActiveRecord::RecordNotFound if conn.blank?

      conn.update!(field_mappings: normalized_mappings)

      redirect_to event_group_connect_service_path(@event_group, @service.identifier)
    end

    private

    def set_event_group
      @event_group = EventGroup.friendly.find(params[:event_group_id])
    end

    def set_service
      @service = ::Connectors::Service::BY_IDENTIFIER[params[:connect_service_id]]
      raise ActiveRecord::RecordNotFound if @service.blank?
    end

    def race_connection
      @event_group.connections.from_service(@service.identifier)
                  .find_by(source_type: @service.resource_map[EventGroup])
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
  end
end
