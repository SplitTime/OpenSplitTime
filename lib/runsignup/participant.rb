module Runsignup
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
    keyword_init: true
  )
end
