# frozen_string_literal: true

module Connectors::Runsignup::Models
  RaceEntry = Struct.new(
    :bib_number,
    :scheduled_start_time,
    :racer,
    keyword_init: true
  )
end
