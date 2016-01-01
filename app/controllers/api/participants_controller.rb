module Api
  class ParticipantsController < Api::BaseController

    private

    def participant_params
      params.require(:participant).permit(:first_name, :last_name, :gender, :birthdate, :home_city, :home_state, :home_country)
    end

    def query_params
      params.permit(:first_name, :last_name, :home_city, :home_country, :home_state, :gender)
    end

  end
end
