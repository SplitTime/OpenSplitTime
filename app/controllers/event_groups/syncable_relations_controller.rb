# frozen_string_literal: true

module EventGroups
  class SyncableRelationsController < ::SyncableRelationsController
    private

    def set_syncable
      @syncable = ::EventGroup.friendly.find(params[:event_group_id])
    end
  end
end
