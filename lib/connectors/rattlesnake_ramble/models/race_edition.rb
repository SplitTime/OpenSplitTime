# frozen_string_literal: true

module Connectors::RattlesnakeRamble::Models
  RaceEdition = Struct.new(
    :id,
    :name,
    :date,
    keyword_init: true
  )
end
