class SplitTimeParameters < Struct.new(:params)

  PERMITTED = [:id, :effort_id, :lap, :split_id, :time_from_start, :bitkey, :sub_split_bitkey,
               :stopped_here, :elapsed_time, :time_of_day, :military_time, :data_status]

  def self.strong_params(params)
    params.require(:split_time).permit(*PERMITTED)
  end

  def self.api_params(params)
    ActiveModelSerializers::Deserialization.jsonapi_parse(params, only: PERMITTED)
  end
end
