module Api
  class RacesController < Api::BaseController

    private

    def race_params
      params.require(:race).permit(:name)
    end

    def query_params
      params.permit(:name)
    end

  end
end
