module Api
  class SplitsController < Api::BaseController

    private

    def split_params
      params.require(:split).permit(:name, :course_id, :location_id, :distance, :order, :vert_gain, :vert_loss)
    end

    def query_params
      # this assumes that an album belongs to an artist and has an :artist_id
      # allowing us to filter by this
      params.permit(:name, :course_id, :location_id)
    end

  end
end
