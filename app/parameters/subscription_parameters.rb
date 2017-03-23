class SubscriptionParameters < Struct.new(:params)

  PERMITTED = [:id, :user_id, :participant_id, :protocol, :resource_key]

  def self.strong_params(params)
    params.require(:subscription).permit(*PERMITTED)
  end

  def self.api_params(params)
    ActiveModelSerializers::Deserialization.jsonapi_parse(params, only: PERMITTED)
  end
end
