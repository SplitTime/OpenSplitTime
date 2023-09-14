# frozen_string_literal: true

module Events
  class ConnectionsController < ::ConnectionsController
    private

    def render_destination_create_view
      render "events/connections/create",
             locals: {
               event: @destination,
               connection: @connection,
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
