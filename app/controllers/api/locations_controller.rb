module Api
  class LocationsController < Api::BaseController

    private

    def location_params
      params.require(:location).permit(:name, :description, :elevation, :latitude, :longitude)
    end

    def query_params
      params.permit(:name, :description, :elevation, :latitude, :longitude)
    end

  end
end
