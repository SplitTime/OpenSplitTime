module Live
  class GatingLocationsController < Live::BaseController
    before_action :set_event_group
    before_action :authorize_crew_access

    # GET /live/event_groups/:event_group_id/gating_locations
    def index
      verify_available_live(@event_group)
      return if performed?

      @presenter = EventGroupPresenter.new(@event_group, params, current_user)
    end

    # GET /live/event_groups/:event_group_id/gating_locations/:id
    #
    # Each gated event has its own board; a location with one gated event goes
    # straight there, and a location with several renders a chooser
    def show
      verify_available_live(@event_group)
      return if performed?

      @gating_location = @event_group.gating_locations.find(params[:id])
      gated_events = @gating_location.gating_location_events

      if gated_events.one?
        redirect_to live_event_group_crew_access_board_path(@event_group, gated_events.first,
                                                            request.query_parameters.except("id", "event_group_id"))
      else
        @presenter = EventGroupPresenter.new(@event_group, params, current_user)
      end
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
