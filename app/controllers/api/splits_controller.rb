module Api
  class SplitsController < Api::BaseController

    private

    def split_params
      params.require(:split).permit(:name, :course_id, :location_id, :distance, :order, :vert_gain, :vert_loss)
    end

    def query_params
      params.permit(:name, :course_id, :location_id)
    end

  end
end
