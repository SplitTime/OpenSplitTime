module Api
  class EventSeriesController < Api::BaseController

    private

    def event_params
      params.require(:event_series).permit(:name)
    end

    def query_params
      # this assumes that an album belongs to an artist and has an :artist_id
      # allowing us to filter by this
      params.permit(:name)
    end

  end
end
