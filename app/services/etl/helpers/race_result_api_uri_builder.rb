# frozen_string_literal: true

module ETL::Helpers
  class RaceResultApiUriBuilder

    def initialize(rr_event_id, rr_api_key)
      @rr_event_id = rr_event_id
      @rr_api_key = rr_api_key
    end

    def full_uri
      URI("http://api.raceresult.com/#{rr_event_id}/#{rr_api_key}")
    end

    private

    attr_reader :rr_event_id, :rr_api_key
  end
end
