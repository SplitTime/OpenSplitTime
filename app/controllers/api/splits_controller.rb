module Api
  class SplitsController < Api::BaseController

    private

    def split_params
      params.require(:split).permit(:name, :course_id, :location_id, :distance, :order, :vert_gain, :vert_loss, :type)
    end

    def query_params
      params.permit(:name, :course_id, :location_id, :type)
    end

  end
end
