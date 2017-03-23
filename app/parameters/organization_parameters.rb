class OrganizationParameters < Struct.new(:params)

  PERMITTED = [:id, :name, :description, :concealed]

  def self.strong_params(params)
    params.require(:organization).permit(*PERMITTED)
  end

  def self.api_params(params)
    ActiveModelSerializers::Deserialization.jsonapi_parse(params, only: PERMITTED)
  end
end
