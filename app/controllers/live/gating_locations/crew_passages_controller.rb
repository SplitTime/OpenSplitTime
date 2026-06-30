module Live
  module GatingLocations
    class CrewPassagesController < Live::BaseController
      include BuildsGatingDisplay

      before_action :set_event_group
      before_action :set_gating_location
      before_action :authorize_crew_access

      # POST /live/event_groups/:event_group_id/gating_locations/:gating_location_id/crew_passages
      def create
        effort = @event_group.efforts.find(params[:effort_id])
        @gating_location.crew_passages.find_or_create_by(effort: effort) { |passage| passage.passed_at = Time.current }
        render_event_frame(effort)
      end

      # DELETE /live/event_groups/:event_group_id/gating_locations/:gating_location_id/crew_passages/:id
      def destroy
        crew_passage = @gating_location.crew_passages.find(params[:id])
        effort = crew_passage.effort
        crew_passage.destroy
        render_event_frame(effort)
      end

      private

      def render_event_frame(effort)
        @display = build_gating_display(@gating_location)
        @gating_location_event = @gating_location.gating_location_events.find_by(event_id: effort.event_id)
        render :update
      end

      def set_event_group
        @event_group = EventGroup.friendly.find(params[:event_group_id])
      end

      def set_gating_location
        @gating_location = @event_group.gating_locations.find(params[:gating_location_id])
      end

      def authorize_crew_access
        authorize @event_group, :crew_access?
      end
    end
  end
end
