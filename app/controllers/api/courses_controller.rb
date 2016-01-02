module Api
  class CoursesController < Api::BaseController

    private

    def course_params
      params.require(:course).permit(:name)
    end

    def query_params
      params.permit(:name)
    end

  end
end
