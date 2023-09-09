# frozen_string_literal: true

module EventGroups
  class ConnectionsController < ::ConnectionsController
    def destroy
      @connection.destroy

      event_connections = Connection.where(
        destination: @destination.events,
        service_identifier: @connection.service_identifier
      )
      event_connections.destroy_all

      render_destination_destroy_view
    end

    private

    def render_destination_create_view
      render :create, locals: { event_group: @destination, connection: @connection, view_context: view_context }
    end

    def render_destination_destroy_view
      render :destroy, locals: { event_group: @destination, connection: @connection, view_context: view_context }
    end

    def new_connection_params
      {
        service_identifier: service_identifier,
        source_type: service.resource_map[EventGroup]
      }
    end

    def set_destination
      @destination = ::EventGroup.friendly.find(params[:event_group_id])
    end
  end
end
