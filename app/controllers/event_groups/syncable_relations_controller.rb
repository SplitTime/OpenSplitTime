# frozen_string_literal: true

module EventGroups
  class SyncableRelationsController < ::SyncableRelationsController
    def new
      respond_to do |format|
        format.turbo_stream do
          @syncable_relation = @syncable.syncable_sources.new(source_name: params[:service_identifier])
          render :new, locals: { syncable_relation: @syncable_relation }
        end
      end
    end

    private

    def set_syncable
      @syncable = ::EventGroup.friendly.find(params[:event_group_id])
    end
  end
end
