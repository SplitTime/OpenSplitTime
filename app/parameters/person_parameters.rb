class PersonParameters < BaseParameters
  def self.permitted
    [:id, :slug, :city, :state_code, :country_code, :first_name, :last_name, :gender, :email, :phone, :birthdate,
     :concealed, :hide_age, :obscure_name, :photo]
  end

  def self.permitted_query
    permitted + [:current_age_from_efforts]
  end
end
