class UserParameters < Struct.new(:params)

  PERMITTED = [:id, :first_name, :last_name, :email, :phone, :http, :https,
               :password, :pref_distance_unit, :pref_elevation_unit]

  def self.strong_params(params)
    params.require(:user).permit(*PERMITTED)
  end

  def self.api_params(params)
    ActiveModelSerializers::Deserialization.jsonapi_parse(params, only: PERMITTED)
  end
end
