module Api
  class ParticipantsController < Api::BaseController

    private

    def participant_params
      params.require(:participant).permit(:first_name, :last_name, :gender, :birthdate, :home_city, :home_state, :home_country)
    end

    def query_params
      # this assumes that an album belongs to an artist and has an :artist_id
      # allowing us to filter by this
      params.permit(:first_name, :last_name, :home_city, :home_country, :home_state, :gender)
    end

  end
end
