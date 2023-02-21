# frozen_string_literal: true

module Connectors
  module Runsignup
    module Request
      class GetRace
        # @param [String] race_id
        def initialize(race_id:)
          @race_id = race_id
        end

        attr_reader :race_id

        # @return [String]
        def url_postfix
          "/race/#{race_id}"
        end

        # @return [Hash]
        def specific_params
          {}
        end

        # # @param [Hash] raw_event
        # # @return [::Runsignup::Resources::Event]
        # def object_from_hash(raw_event)
        #   Runsignup::Resources::Event.new(
        #     id: raw_event["event_id"],
        #     name: raw_event["name"],
        #     start_time: raw_event["start_time"],
        #     end_time: raw_event["end_time"],
        #   )
        # end
      end
    end
  end
end
