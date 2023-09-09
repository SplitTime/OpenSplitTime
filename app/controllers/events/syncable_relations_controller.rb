# frozen_string_literal: true

module Events
  class SyncableRelationsController < ::SyncableRelationsController
    private

    def render_syncable_create_view
      render "events/syncable_sources/create",
             locals: {
               event_group: @syncable.event_group,
               event: @syncable,
               external_id: params.dig(:syncable_relation, :source_id),
               external_name: params.dig(:syncable_relation, :external_name),
             }
    end

    def render_syncable_destroy_view
      render_syncable_create_view
    end

    def set_syncable
      @syncable = ::Event.friendly.find(params[:event_id])
    end
  end
end
