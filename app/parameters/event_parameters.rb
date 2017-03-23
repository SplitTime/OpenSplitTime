class EventParameters < Struct.new(:params)

  PERMITTED = [:id, :course_id, :organization_id, :name, :start_time, :concealed,
               :available_live, :beacon_url, :laps_required, :staging_id]

  def self.strong_params(params)
    params.require(:event).permit(*PERMITTED)
  end

  def self.api_params(params)
    ActiveModelSerializers::Deserialization.jsonapi_parse(params, only: PERMITTED)
  end
end
