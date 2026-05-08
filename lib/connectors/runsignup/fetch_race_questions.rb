module Connectors
  module Runsignup
    # Returns the catalog of distinct registration questions configured on a
    # Runsignup race. Runsignup doesn't expose a dedicated questions endpoint,
    # so this hits /participants with include_questions=T (small page) and
    # extracts unique (question_id, question_text) pairs.
    #
    # Cached briefly because the catalog is stable across page loads and the
    # field-mapping UI re-fetches on every render of the connection page.
    class FetchRaceQuestions
      SAMPLE_PAGE_SIZE = 10
      CACHE_TTL = 5.minutes

      # @param [String, Integer] race_id
      # @param [String, Integer] event_id  any Runsignup event_id under the race
      # @param [User] user
      # @param [::Connectors::Runsignup::Client, nil] client
      # @return [Array<::Connectors::Runsignup::Models::Question>]
      def self.perform(race_id:, event_id:, user:, client: nil)
        new(race_id: race_id, event_id: event_id, user: user, client: client).perform
      end

      def initialize(race_id:, event_id:, user:, client: nil)
        @race_id = race_id.to_i
        @event_id = event_id.to_i
        @user = user
        @client = client || ::Connectors::Runsignup::Client.new(user)
      end

      # @return [Array<::Connectors::Runsignup::Models::Question>]
      def perform
        Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) { fetch_uncached }
      end

      private

      attr_reader :race_id, :event_id, :user, :client

      def cache_key
        "runsignup/race/#{race_id}/event/#{event_id}/questions"
      end

      def fetch_uncached
        body = client.get_participants(race_id, event_id, 1)
        parsed = JSON.parse(body)
        parsed = parsed.first if parsed.is_a?(Array)
        participants = (parsed["participants"] || []).first(SAMPLE_PAGE_SIZE)

        seen = {}
        participants.each do |participant|
          (participant["question_responses"] || []).each do |response|
            question_id = response["question_id"]
            next if question_id.blank? || seen.key?(question_id)

            seen[question_id] = ::Connectors::Runsignup::Models::Question.new(
              id: question_id,
              text: response["question_text"].to_s.strip,
            )
          end
        end

        seen.values.sort_by(&:id)
      end
    end
  end
end
