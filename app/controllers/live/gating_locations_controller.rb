module Live
  class GatingLocationsController < Live::BaseController
    include BuildsGatingDisplay

    before_action :set_event_group
    before_action :authorize_crew_access

    # GET /live/event_groups/:event_group_id/gating_locations
    def index
      verify_available_live(@event_group)
      return if performed?

      @presenter = EventGroupPresenter.new(@event_group, params, current_user)
    end

    # GET /live/event_groups/:event_group_id/gating_locations/:id
    def show
      verify_available_live(@event_group)
      return if performed?

      @presenter = EventGroupPresenter.new(@event_group, params, current_user)
      @display = build_gating_display(@event_group.gating_locations.find(params[:id]))
    end

    private

    def set_event_group
      @event_group = EventGroup.friendly.find(params[:event_group_id])
    end

    def authorize_crew_access
      authorize @event_group, :crew_access?
    end
  end
end
