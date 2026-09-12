module Connectors
  module RattlesnakeRamble
    module Models
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
  end
end
