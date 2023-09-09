# frozen_string_literal: true

module EventGroups
  class SyncableRelationsController < ::SyncableRelationsController

    private

    def render_syncable_create_view
      render :create, locals: { event_group: @syncable, syncable_source: @syncable_source, view_context: view_context }
    end

    def render_syncable_destroy_view
      render :destroy, locals: { event_group: @syncable, syncable_source: @syncable_source, view_context: view_context }
    end

    def new_syncable_source_params
      {
        source_name: service_identifier,
        destination_name: "internal",
        source_type: service.resource_map[EventGroup]
      }
    end

    def set_syncable
      @syncable = ::EventGroup.friendly.find(params[:event_group_id])
    end
  end
end
