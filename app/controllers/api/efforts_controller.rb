module Api
  class EffortsController < Api::BaseController

    private

    def effort_params
      params.require(:effort).permit(:name, :event_id, :participant_id, :wave, :bib_number, :effort_city, :effort_state, :effort_country, :effort_age, :start_time, :finished)
    end

    def query_params
      params.permit(:name, :event_id, :participant_id, :wave, :bib_number, :effort_city, :effort_state, :effort_country, :finished)
    end

  end
end
