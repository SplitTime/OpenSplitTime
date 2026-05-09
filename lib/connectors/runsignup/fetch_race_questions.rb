module Connectors
  module Runsignup
    # Returns the catalog of distinct registration questions configured on a
    # Runsignup race via the dedicated /Rest/race/{race_id}?include_questions=T
    # endpoint, which gives us the question definitions directly without
    # paginating through participants.
    #
    # Cached briefly because the catalog is stable across page loads and the
    # field-mapping UI re-fetches on every render of the connection page.
    class FetchRaceQuestions
      CACHE_TTL = 5.minutes

      # @param [String, Integer] race_id
      # @param [User] user
      # @param [::Connectors::Runsignup::Client, nil] client
      # @return [Array<::Connectors::Runsignup::Models::Question>]
      def self.perform(race_id:, user:, client: nil)
        new(race_id: race_id, user: user, client: client).perform
      end

      def initialize(race_id:, user:, client: nil)
        @race_id = race_id.to_i
        @user = user
        @client = client || ::Connectors::Runsignup::Client.new(user)
      end

      # @return [Array<::Connectors::Runsignup::Models::Question>]
      def perform
        Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) { fetch_uncached }
      end

      private

      attr_reader :race_id, :user, :client

      def cache_key
        "runsignup/race/#{race_id}/questions"
      end

      def fetch_uncached
        body = client.get_race(race_id, include_questions: true)
        parsed = JSON.parse(body)
        parsed = parsed.first if parsed.is_a?(Array)

        questions = parsed.dig("race", "questions") || []
        questions.map do |q|
          ::Connectors::Runsignup::Models::Question.new(
            q["question_id"],
            q["question_text"].to_s.strip,
          )
        end
      end
    end
  end
end
