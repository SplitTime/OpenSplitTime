class HistoricalFactParameters < BaseParameters
  def self.csv_export_attributes
    %w[
      kind
      year
      quantity
      comments
      first_name
      last_name
      gender
      birthdate
      address
      city
      state_code
      country_code
      email
      phone
    ]
  end

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
      :kind,
      :year,
      :quantity,
      :comments,
      :external_id,
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
      order_id: :external_id,
    }
  end
end
