# frozen_string_literal: true

module Runsignup
  class GetParticipants
    BASE_URL = "https://runsignup.com/Rest"
    BATCH_SIZE = 50

    def self.perform(race_id:, event_id:, user:)
      new(race_id: race_id, event_id: event_id, user: user).perform
    end

    def initialize(race_id:, event_id:, user:)
      @race_id = race_id
      @event_id = event_id
      @user = user
      @participants = []
    end

    def perform
      page = 1

      loop do
        params = base_params.merge(page: page)
        response = ::RestClient.get(url, { params: params })
        body = JSON.parse(response.body)
        body = body.first if body.is_a?(Array)
        raw_participants = body["participants"]

        break if raw_participants.blank?

        raw_participants.each { |raw_participant| participants << participant_from_raw(raw_participant) }
        page += 1
      end

      participants
    end

    private

    attr_reader :race_id, :event_id, :user, :participants

    def url
      BASE_URL + "/race/#{race_id}/participants"
    end

    def base_params
      {
        api_key: credentials["api_key"],
        api_secret: credentials["api_secret"],
        event_id: event_id,
        format: :json,
        results_per_page: BATCH_SIZE,
        sort: "registration_id ASC",
      }
    end

    def credentials
      @credentials ||= user.credentials["runsignup"] || {}
    end

    def participant_from_raw(raw_participant)
      ::Runsignup::Participant.new(
        first_name: raw_participant.dig("user", "first_name"),
        last_name: raw_participant.dig("user", "last_name"),
        birthdate: raw_participant.dig("user", "dob"),
        gender: convert_gender(raw_participant.dig("user", "gender")),
        email: raw_participant.dig("user", "email"),
        phone: raw_participant.dig("user", "phone"),
        city: raw_participant.dig("user", "address", "city"),
        state_code: raw_participant.dig("user", "address", "state"),
        country_code: raw_participant.dig("user", "address", "country_code"),
        bib_number: raw_participant.dig("bib_num"),
      )
    end

    def convert_gender(string)
      if string.first.downcase == "m"
        "male"
      else
        "female"
      end
    end
  end
end
