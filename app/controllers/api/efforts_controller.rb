module Api
  class EffortsController < Api::BaseController

    private

    def effort_params
      params.require(:effort).permit(:name, :event_id, :participant_id, :wave, :bib_number, :city, :state, :country_id, :age, :start_time, :dropped)
    end

    def query_params
      params.permit(:name, :event_id, :participant_id, :wave, :bib_number, :city, :state, :country_id, :age, :start_time, :dropped)
    end

  end
end
