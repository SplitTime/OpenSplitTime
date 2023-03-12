# frozen_string_literal: true

module Runsignup
  class GetEvents
    BASE_URL = "https://runsignup.com/Rest"

    # @param [String] race_id
    # @param [User] user
    # @return [Array<::Runsignup::Event>]
    def self.perform(race_id:, user:)
      new(race_id: race_id, user: user).perform
    end

    # @param [String] race_id
    # @param [User] user
    def initialize(race_id:, user:)
      @race_id = race_id
      @user = user
      @events = []
    end

    # @return [Array<::Runsignup::Event>]
    def perform
      return unless credentials.present?

      raw_events = parsed_body.dig("race", "events")
      return unless raw_events.present?

      raw_events.each { |raw_event| events << event_from_raw(raw_event) }

      events
    end

    private

    attr_reader :race_id, :user, :events

    # @return [Hash, nil]
    def parsed_body
      response = ::RestClient.get(url, { params: base_params })
      body = JSON.parse(response.body)
      body = body.first if body.is_a?(Array)
      body
    end

    # @return [String]
    def url
      BASE_URL + "/race/#{race_id}"
    end

    # @return [Hash]
    def base_params
      {
        api_key: credentials["api_key"],
        api_secret: credentials["api_secret"],
        format: :json,
      }
    end

    # @return [Hash, nil]
    def credentials
      @credentials ||= user.credentials&.dig("runsignup")
    end

    # @param [Hash] raw_event
    # @return [::Runsignup::Event]
    def event_from_raw(raw_event)
      ::Runsignup::Event.new(
        id: raw_event["event_id"],
        name: raw_event["name"],
        start_time: raw_event["start_time"],
        end_time: raw_event["end_time"],
        )
    end
  end
end
