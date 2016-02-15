module Api
  class SplitTimesController < Api::BaseController

    private

    def split_time_params
      params.require(:split_time).permit(:effort_id, :split_id, :time_from_start, :data_status)
    end

    def query_params
      params.permit(:effort_id, :split_id, :time_from_start, :data_status)
    end

  end
end
