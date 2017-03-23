class ParticipantParameters < Struct.new(:params)

  PERMITTED = [:id, :city, :state_code, :country_code, :first_name, :last_name, :gender,
               :email, :phone, :birthdate, :concealed]

  def self.strong_params(params)
    params.require(:participant).permit(*PERMITTED)
  end

  def self.api_params(params)
    ActiveModelSerializers::Deserialization.jsonapi_parse(params, only: PERMITTED)
  end
end
