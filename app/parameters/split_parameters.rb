class SplitParameters < BaseParameters

  def self.permitted
    [:id, :course_id, :split_id, :distance_from_start, :distance, :vert_gain_from_start, :vert_gain,
     :vert_loss_from_start, :vert_loss, :kind, :base_name, :description, :sub_split_bitmap, :latitude, :longitude,
     :elevation, :elevation_in_preferred_units, :name_extensions]
  end

  def self.csv_attributes
    %w(base_name distance kind vert_gain vert_loss latitude longitude elevation)
  end

  def self.mapping
    {name: :base_name}
  end
end
