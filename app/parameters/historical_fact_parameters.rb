# frozen_string_literal: true

class HistoricalFactParameters < BaseParameters
  def self.permitted
    [
      :first_name,
      :last_name,
      :gender,
      :birthdate,
      :address,
      :city,
      :state_code,
      :country_code,
      :phone,
      :email,
      :emergency_contact,
      :emergency_phone,
    ]
  end

  def self.mapping
    {
      first: :first_name,
      last: :last_name,
      street_address: :address,
      state: :state_code,
      country: :country_code,
      dob: :birthdate,
      "phone_#": :phone,
      email_address: :email,
    }
  end
end
