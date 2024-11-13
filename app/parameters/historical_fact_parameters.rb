# frozen_string_literal: true

class HistoricalFactParameters < BaseParameters
  def self.mapping
    {
      state: :state_code,
      country: :country_code,
      dob: :birthdate,
      emergency_name: :emergency_contact,
    }
  end
end
