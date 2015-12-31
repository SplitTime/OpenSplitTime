module Api
  class EffortsController < Api::BaseController

    private

    def effort_params
      params.require(:effort).permit(:name, :event_id, :participant_id, :wave, :bib_number, :effort_city, :effort_state, :effort_country, :effort_age, :start_time, :finished)
    end

    def query_params
      # this assumes that an album belongs to an artist and has an :artist_id
      # allowing us to filter by this
      params.permit(:name, :event_id, :participant_id, :wave, :bib_number, :effort_city, :effort_state, :effort_country, :finished)
    end

  end
end
