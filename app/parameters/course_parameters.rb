class CourseParameters < Struct.new(:params)

  PERMITTED = [:id, :name, :description, :next_start_time, splits_attributes: [*SplitParameters::PERMITTED]]

  def self.strong_params(params)
    params.require(:course).permit(*PERMITTED)
  end

  def self.api_params(params)
    ActiveModelSerializers::Deserialization.jsonapi_parse(params, only: PERMITTED)
  end
end
