# frozen_string_literal: true

module Connectors::RattlesnakeRamble::Models
  RaceEntry = Struct.new(
    :bib_number,
    :scheduled_start_time,
    :racer,
    keyword_init: true
  ) do

    def first_name
      racer&.first_name
    end

    def last_name
      racer&.last_name
    end

    def gender
      racer&.gender
    end

    def birthdate
      racer&.birth_date
    end

    def email
      racer&.email
    end

    def city
      racer&.city
    end

    def state_code
      racer&.state
    end
  end
end
