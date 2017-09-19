class PersonParameters < BaseParameters

  def self.permitted
    [:id, :city, :state_code, :country_code, :first_name, :last_name, :gender, :email, :phone, :birthdate, :concealed]
  end

  def self.permitted_query
    permitted + [:current_age_from_efforts]
  end
end
