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

      # Controls submissions and periodic refreshes target a single card's
      # frame; rendering just that card skips row computation for the others
      requested_gle = @display.gated_events.find { |gle| gle.id.to_s == params[:gating_location_event_id].to_s }
      return unless turbo_frame_request? && requested_gle

      render partial: "live/gating_locations/event_rows",
             locals: { gating_location_event: requested_gle, display: @display }
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
