# frozen_string_literal: true

module Runsignup
  class GetParticipants
    BASE_URL = "https://runsignup.com/Rest"
    BATCH_SIZE = 50

    # @param [String] race_id
    # @param [String] event_id
    # @param [User] user
    # @return [Array<::Runsignup::Participant>]
    def self.perform(race_id:, event_id:, user:)
      new(race_id: race_id, event_id: event_id, user: user).perform
    end

    # @param [String] race_id
    # @param [String] event_id
    # @param [User] user
    def initialize(race_id:, event_id:, user:)
      @race_id = race_id.to_i
      @event_id = event_id.to_i
      @user = user
      @participants = []
    end

    # @return [Array<::Runsignup::Participant>]
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

    # @return [String]
    def url
      BASE_URL + "/race/#{race_id}/participants"
    end

    # @return [Hash{Symbol->Symbol | Integer}]
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

    # @return [Hash, nil]
    def credentials
      @credentials ||= user.credentials&.dig("runsignup")
    end

    # @return [String, nil]
    def event_start_time
      return @event_start_time if defined?(@event_start_time)

      events = ::Runsignup::GetEvents.perform(race_id: race_id, user: user)
      event = events.find { |event| event.id == event_id }
      @event_start_time = event&.start_time
    end

    # @param [Hash] raw_participant
    # @return [::Runsignup::Participant]
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
        scheduled_start_time_local: event_start_time,
        )
    end

    # @param [String] string
    # @return [String (frozen)]
    def convert_gender(string)
      if string.first.downcase == "m"
        "male"
      else
        "female"
      end
    end
  end
end
