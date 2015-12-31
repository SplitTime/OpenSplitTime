module Api
  class LocationsController < Api::BaseController

    private

    def location_params
      params.require(:location).permit(:name, :elevation, :latitude, :longitude)
    end

    def query_params
      # this assumes that an album belongs to an artist and has an :artist_id
      # allowing us to filter by this
      params.permit(:name)
    end

  end
end
