module Api
  class SplitsController < Api::BaseController

    private

    def split_params
      params.require(:split).permit(:name, :course_id, :location_id, :distance_from_start,
                                    :sub_order, :vert_gain_from_start, :vert_loss_from_start, :kind)
    end

    def query_params
      params.permit(:name, :course_id, :location_id, :distance_from_start, :sub_order,
                    :vert_gain_from_start, :vert_loss_from_start, :kind)
    end

  end
end
