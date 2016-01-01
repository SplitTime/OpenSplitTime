module Api
  class LocationsController < Api::BaseController

    private

    def location_params
      params.require(:location).permit(:name, :elevation, :latitude, :longitude)
    end

    def query_params
      params.permit(:name)
    end

  end
end
