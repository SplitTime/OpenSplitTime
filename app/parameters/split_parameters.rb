class SplitParameters < BaseParameters

  def self.permitted
    [:id, :course_id, :split_id, :distance_from_start, :distance_as_entered, :vert_gain_from_start,
     :vert_gain_as_entered, :vert_loss_from_start, :vert_loss_as_entered, :kind, :base_name,
     :description, :sub_split_bitmap, :latitude, :longitude, :elevation, :elevation_as_entered,
     :name_extensions]
  end

  def self.csv_attributes
    %w(base_name distance_from_start vert_gain_from_start vert_loss_from_start latitude longitude elevation)
  end
end
