class SplitParameters < Struct.new(:params)

  PERMITTED = [:id, :course_id, :split_id, :distance_from_start, :distance_as_entered, :vert_gain_from_start,
               :vert_gain_as_entered, :vert_loss_from_start, :vert_loss_as_entered, :kind, :base_name,
               :description, :sub_split_bitmap, :latitude, :longitude, :elevation, :elevation_as_entered,
               :name_extensions]

  def self.strong_params(params)
    params.require(:split).permit(*PERMITTED)
  end

  def self.api_params(params)
    ActiveModelSerializers::Deserialization.jsonapi_parse(params, only: PERMITTED)
  end
end
