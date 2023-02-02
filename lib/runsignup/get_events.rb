# frozen_string_literal: true

module Runsignup
  class GetEvents
    BASE_URL = "https://runsignup.com/Rest"

    def self.perform(race_id:, user:)
      new(race_id: race_id, user: user).perform
    end

    def initialize(race_id:, user:)
      @race_id = race_id
      @user = user
      @events = []
    end

    def perform
      response = ::RestClient.get(url, { params: base_params })
      body = JSON.parse(response.body)
      body = body.first if body.is_a?(Array)
      raw_events = body.dig("race", "events")
      raw_events.each { |raw_event| events << event_from_raw(raw_event) }

      events
    end

    private

    attr_reader :race_id, :user, :events

    def url
      BASE_URL + "/race/#{race_id}"
    end

    def base_params
      {
        api_key: credentials["api_key"],
        api_secret: credentials["api_secret"],
        format: :json,
      }
    end

    def credentials
      @credentials ||= user.credentials["runsignup"] || {}
    end

    def event_from_raw(raw_event)
      OpenStruct.new(
        id: raw_event["event_id"],
        name: raw_event["name"],
        start_time: raw_event["start_time"],
        end_time: raw_event["end_time"],
      )
    end
  end
end
