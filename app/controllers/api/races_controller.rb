module Api
  class RacesController < Api::BaseController

    private

    def race_params
      params.require(:race).permit(:name, :description)
    end

    def query_params
      params.permit(:name, :description)
    end

  end
end
