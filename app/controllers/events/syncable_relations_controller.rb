# frozen_string_literal: true

module Events
  class SyncableRelationsController < ::SyncableRelationsController
    private

    def render_syncable_view
      render "events/replace_syncable_switch",
             locals: {
               event_group: @syncable.event_group,
               event: @syncable,
               external_id: params.dig(:syncable_relation, :source_id),
               external_name: params.dig(:syncable_relation, :external_name),
             }
    end

    def set_syncable
      @syncable = ::Event.friendly.find(params[:event_id])
    end
  end
end
