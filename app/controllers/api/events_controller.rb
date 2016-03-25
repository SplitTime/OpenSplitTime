module Api
  class EventsController < Api::BaseController

    private

    def event_params
      params.require(:event).permit(:name, :course_id, :first_start_time, :race_id)
    end

    def query_params
      params.permit(:name, :course_id, :first_start_time, :race_id)
    end

  end
end
