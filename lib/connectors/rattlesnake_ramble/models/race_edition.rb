module Connectors
  module RattlesnakeRamble
    module Models
      RaceEdition = Struct.new(
        :id,
        :date,
        :race_name
      ) do
        def name
          race_name
        end

        def start_time
          date.in_time_zone("UTC")
        end
      end
    end
  end
end
