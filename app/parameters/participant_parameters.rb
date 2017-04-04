class ParticipantParameters < BaseParameters

  def self.permitted
    [:id, :city, :state_code, :country_code, :first_name, :last_name, :gender, :email, :phone, :birthdate, :concealed]
  end
end
