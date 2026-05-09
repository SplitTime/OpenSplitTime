module Connectors
  module Runsignup
    module Request
      class GetRace
        # @param [String] race_id
        # @param [Boolean] include_questions
        def initialize(race_id:, include_questions: false)
          @race_id = race_id
          @include_questions = include_questions
        end

        attr_reader :race_id

        # @return [String]
        def url_postfix
          "/race/#{race_id}"
        end

        # @return [Hash]
        def specific_params
          @include_questions ? { include_questions: "T" } : {}
        end
      end
    end
  end
end
