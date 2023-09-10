# frozen_string_literal: true

module Connectors::Runsignup::Models
  Racer = Struct.new(
    :first_name,
    :last_name,
    :gender,
    :birth_date,
    :email,
    :city,
    :state,
    keyword_init: true
  )
end
