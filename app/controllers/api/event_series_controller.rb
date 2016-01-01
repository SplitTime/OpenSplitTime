module Api
  class EventSeriesController < Api::BaseController

    private

    def event_series_params
      params.require(:event_series).permit(:name)
    end

    def query_params
      params.permit(:name)
    end

  end
end
