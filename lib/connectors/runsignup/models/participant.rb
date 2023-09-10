# frozen_string_literal: true

module Connectors::Runsignup::Models
  Participant = Struct.new(
    :first_name,
    :last_name,
    :birthdate,
    :gender,
    :bib_number,
    :city,
    :state_code,
    :country_code,
    :email,
    :phone,
    :scheduled_start_time_local,
    keyword_init: true
  )
end
