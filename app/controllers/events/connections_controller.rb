# frozen_string_literal: true

module Events
  class ConnectionsController < ::ConnectionsController
    private

    def render_destination_create_view
      render "events/connections/create",
             locals: {
               event_group: @destination.event_group,
               event: @destination,
               external_id: params.dig(:connection, :source_id),
               external_name: params.dig(:connection, :external_name),
               service_identifier: @connection.service_identifier,
             }
    end

    def render_destination_destroy_view
      render_destination_create_view
    end

    def set_destination
      @destination = ::Event.friendly.find(params[:event_id])
    end
  end
end
