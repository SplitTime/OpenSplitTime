module Api
  class CoursesController < Api::BaseController

    private

    def course_params
      params.require(:course).permit(:name, :start_location_id, :end_location_id)
    end

    def query_params
      params.permit(:name, :start_location_id, :end_location_id)
    end

  end
end
