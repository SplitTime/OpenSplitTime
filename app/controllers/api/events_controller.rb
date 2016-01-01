module Api
  class EventsController < Api::BaseController

    private

    def event_params
      params.require(:event).permit(:name, :course_id, :start_date)
    end

    def query_params
      params.permit(:name, :course_id)
    end

  end
end
