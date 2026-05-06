module Connectors
  module Runsignup
    class FetchEventParticipants
      BATCH_SIZE = 50

      # @param [String] race_id
      # @param [String] event_id
      # @param [User] user
      # @param [Array<Hash>] field_mappings — see Connection#field_mappings
      # @return [Array<::Connectors::Runsignup::Models::Participant>]
      def self.perform(race_id:, event_id:, user:, field_mappings: [])
        new(race_id: race_id, event_id: event_id, user: user, field_mappings: field_mappings).perform
      end

      # @param [String] race_id
      # @param [String] event_id
      # @param [User] user
      # @param [Array<Hash>] field_mappings
      # @param [::Connectors::Runsignup::Client, nil] client
      def initialize(race_id:, event_id:, user:, field_mappings: [], client: nil)
        @race_id = race_id.to_i
        @event_id = event_id.to_i
        @user = user
        @field_mappings = (field_mappings || []).map(&:to_h)
        @client = client || Connectors::Runsignup::Client.new(user)
        @participants = []
      end

      # @return [Array<::Connectors::Runsignup::Models::Participant>]
      def perform
        page = 1

        loop do
          body = client.get_participants(race_id, event_id, page)
          parsed_body = JSON.parse(body)
          parsed_body = parsed_body.first if parsed_body.is_a?(Array)

          raw_participants = parsed_body["participants"]

          break if raw_participants.blank?

          raw_participants.each { |raw_participant| participants << participant_from_raw(raw_participant) }
          page += 1
        end

        participants
      end

      private

      attr_reader :race_id, :event_id, :user, :client, :participants, :field_mappings

      # @return [String, nil]
      def event_start_time
        return @event_start_time if defined?(@event_start_time)

        events = ::Connectors::Runsignup::FetchRaceEvents.perform(race_id: race_id, user: user, client: client)
        event = events.find { |event| event.id == event_id }
        @event_start_time = event&.start_time
      end

      # @param [Hash] raw_participant
      # @return [::Connectors::Runsignup::Models::Participant]
      def participant_from_raw(raw_participant)
        attrs = {
          first_name: raw_participant.dig("user", "first_name"),
          last_name: raw_participant.dig("user", "last_name"),
          birthdate: raw_participant.dig("user", "dob"),
          gender: convert_gender(raw_participant.dig("user", "gender")),
          email: raw_participant.dig("user", "email"),
          phone: raw_participant.dig("user", "phone"),
          city: raw_participant.dig("user", "address", "city"),
          state_code: raw_participant.dig("user", "address", "state"),
          country_code: raw_participant.dig("user", "address", "country_code"),
          bib_number: raw_participant["bib_num"],
          scheduled_start_time_local: event_start_time,
        }
        attrs.merge!(attributes_from_field_mappings(raw_participant))

        ::Connectors::Runsignup::Models::Participant.new(**attrs)
      end

      # Routes per-question response values into the configured destination
      # slots. See Connection#field_mappings for the expected shape.
      # @param [Hash] raw_participant
      # @return [Hash{Symbol=>String}]
      def attributes_from_field_mappings(raw_participant)
        return {} if field_mappings.blank?

        responses_by_id = (raw_participant["question_responses"] || []).index_by { |r| r["question_id"] }
        comments_parts = []
        attrs = {}

        field_mappings.each do |mapping|
          response_obj = responses_by_id[mapping["source_question_id"]]
          next if response_obj.blank?

          raw_value = response_obj["response"].presence ||
                      Array(response_obj["responses"]).compact_blank.join(", ").presence
          next if raw_value.blank?
          next if mapping["suppress_when"].present? && raw_value == mapping["suppress_when"]

          value = mapping["value_when_present"].presence || raw_value

          case mapping["destination"]
          when "comments"
            comments_parts << value
          when "emergency_contact", "emergency_phone"
            attrs[mapping["destination"].to_sym] = value
          end
        end

        attrs[:comments] = comments_parts.join(", ") if comments_parts.any?
        attrs
      end

      # @param [String] string
      # @return [String (frozen)]
      def convert_gender(string)
        case string&.first&.downcase
        when "m"
          "male"
        when "f"
          "female"
        else
          "nonbinary"
        end
      end
    end
  end
end
