module Live
  class CrewAccessBoardsController < Live::BaseController
    include BuildsCrewAccessBoard

    before_action :set_event_group
    before_action :authorize_crew_access

    # GET /live/event_groups/:event_group_id/crew_access_boards/:id
    def show
      verify_available_live(@event_group)
      return if performed?

      @presenter = EventGroupPresenter.new(@event_group, params, current_user)
      @board = build_crew_access_board(@event_group.gating_location_events.find(params[:id]))
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
