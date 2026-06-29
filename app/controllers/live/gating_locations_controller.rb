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
    def show
      verify_available_live(@event_group)
      return if performed?

      @presenter = EventGroupPresenter.new(@event_group, params, current_user)
      @gating_location = @event_group.gating_locations.find(params[:id])
      @display = GatingLocationLiveDisplay.new(gating_location: @gating_location)
      @adjusted_buffers = adjusted_buffers
    end

    private

    def set_event_group
      @event_group = EventGroup.friendly.find(params[:event_group_id])
    end

    def authorize_crew_access
      authorize @event_group, :crew_access?
    end

    # When a steward adjusts one gated event's buffer, that event_id + buffer arrive as params;
    # every other event keeps its saved default_travel_buffer.
    def adjusted_buffers
      gating_location_event_id = params[:gating_location_event_id].to_i
      buffer = params[:buffer].presence
      return {} unless gating_location_event_id.positive? && buffer

      { gating_location_event_id => buffer.to_i.clamp(0, 1200) }
    end
  end
end
