module Api
  class CoursesController < Api::BaseController

    private

    def course_params
      params.require(:course).permit(:name, :start_location_id, :end_location_id)
    end

    def query_params
      # this assumes that an album belongs to an artist and has an :artist_id
      # allowing us to filter by this
      params.permit(:name, :start_location_id, :end_location_id)
    end

  end
end
