class EffortParameters < Struct.new(:params)

  PERMITTED = [:id, :event_id, :participant_id, :first_name, :last_name, :gender, :wave, :bib_number, :age, :birthdate,
               :city, :state_code, :country_code, :finished, :concealed, :start_time, :start_offset,
               :beacon_url, :report_url, :photo_url, :phone, :email,
               split_times_attributes: [*SplitTimeParameters::PERMITTED]]

  def self.strong_params(params)
    params.require(:effort).permit(*PERMITTED)
  end

  def self.api_params(params)
    ActiveModelSerializers::Deserialization.jsonapi_parse(params, only: PERMITTED)
  end
end
