module BuildsGatingDisplay
  private

  # Builds the Crew Access display for a gating location, applying the steward's control params
  # (buffer, sort, hide filters, search) for the event whose form was submitted.
  def build_gating_display(gating_location)
    GatingLocationLiveDisplay.new(
      gating_location: gating_location,
      adjusted_event_id: params[:gating_location_event_id],
      adjusted_buffer: params[:buffer],
      sort: params[:sort],
      hide_departed: params[:hide_departed],
      hide_passed: params[:hide_passed],
      search: params[:search],
    )
  end
end
