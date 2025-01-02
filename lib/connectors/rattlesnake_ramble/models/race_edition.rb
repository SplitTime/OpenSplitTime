module Connectors::RattlesnakeRamble::Models
  RaceEdition = Struct.new(
    :id,
    :date,
    :race_name,
    keyword_init: true
  ) do

    def name
      race_name
    end

    def start_time
      date.in_time_zone("UTC")
    end
  end
end
