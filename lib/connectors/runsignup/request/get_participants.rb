# frozen_string_literal: true

module Connectors
  module Runsignup
    module Request
      class GetParticipants
        BATCH_SIZE = 200

        # @param [String] race_id
        # @param [String] event_id
        # @param [String] page
        def initialize(race_id:, event_id:, page:)
          @race_id = race_id.to_i
          @event_id = event_id.to_i
          @page = page.to_i
        end

        attr_reader :race_id, :event_id, :page

        # @return [String]
        def url_postfix
          "/race/#{race_id}/participants"
        end

        # @return [Hash{Symbol->Symbol | Integer}]
        def specific_params
          {
            event_id: event_id,
            page: page,
            results_per_page: BATCH_SIZE,
            sort: "registration_id ASC",
          }
        end

        # # @return [String, nil]
        # def event_start_time
        #   return @event_start_time if defined?(@event_start_time)
        #
        #   events = GetRace.perform(race_id: race_id, user: user)
        #   event = events.find { |event| event.id == event_id }
        #   @event_start_time = event&.start_time
        # end

        # # @param [Hash] raw_participant
        # # @return [::Runsignup::Participant]
        # def participant_from_raw(raw_participant)
        #   Runsignup::Participant.new(
        #     first_name: raw_participant.dig("user", "first_name"),
        #     last_name: raw_participant.dig("user", "last_name"),
        #     birthdate: raw_participant.dig("user", "dob"),
        #     gender: convert_gender(raw_participant.dig("user", "gender")),
        #     email: raw_participant.dig("user", "email"),
        #     phone: raw_participant.dig("user", "phone"),
        #     city: raw_participant.dig("user", "address", "city"),
        #     state_code: raw_participant.dig("user", "address", "state"),
        #     country_code: raw_participant.dig("user", "address", "country_code"),
        #     bib_number: raw_participant.dig("bib_num"),
        #     scheduled_start_time_local: event_start_time,
        #   )
        # end

        # # @param [String] string
        # # @return [String (frozen)]
        # def convert_gender(string)
        #   if string.first.downcase == "m"
        #     "male"
        #   else
        #     "female"
        #   end
        # end
      end
    end
  end
end
