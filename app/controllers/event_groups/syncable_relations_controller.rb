# frozen_string_literal: true

module EventGroups
  class SyncableRelationsController < ::SyncableRelationsController

    private

    def render_syncable_new_view
      render :new, locals: { syncable_relation: @syncable_relation }
    end

    def render_syncable_create_view
      super
    end

    def render_syncable_destroy_view
      super
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
