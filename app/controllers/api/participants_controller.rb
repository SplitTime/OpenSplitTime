module Api
  class ParticipantsController < Api::BaseController

    private

    def participant_params
      params.require(:participant).permit(:first_name, :last_name, :gender, :birthdate, :city, :state, :country_id, :email, :phone)
    end

    def query_params
      params.permit(:first_name, :last_name, :gender, :birthdate, :city, :state, :country_id, :email, :phone)
    end

  end
end
