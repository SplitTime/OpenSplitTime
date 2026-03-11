module Connectors
  module Runsignup
    module Models
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
        :scheduled_start_time_local
      )
    end
  end
end
