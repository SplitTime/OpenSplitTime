module BuildsCrewAccessBoard
  private

  # Builds the Crew Access board for one gated event, applying the steward's control
  # params (buffer, sort, hide filters, search)
  def build_crew_access_board(gating_location_event)
    CrewAccessBoardDisplay.new(
      gating_location_event: gating_location_event,
      buffer: params[:buffer],
      sort: params[:sort],
      hide_departed: params[:hide_departed],
      hide_passed: params[:hide_passed],
      search: params[:search],
    )
  end
end
