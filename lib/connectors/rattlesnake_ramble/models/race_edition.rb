# frozen_string_literal: true

module Connectors::RattlesnakeRamble::Models
  RaceEdition = Struct.new(
    :id,
    :date,
    :race_name,
    keyword_init: true
  )
end
