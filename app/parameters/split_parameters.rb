# frozen_string_literal: true

class SplitParameters < BaseParameters

  def self.permitted
    [:id, :course_id, :split_id, :distance_from_start, :distance, :distance_in_preferred_units,
     :vert_gain_from_start, :vert_gain, :vert_gain_in_preferred_units, :vert_loss_from_start, :vert_loss,
     :vert_loss_in_preferred_units, :kind, :base_name, :description, :sub_split_bitmap, :latitude, :longitude,
     :elevation, :elevation_in_preferred_units, :name_extensions, :sub_split_kinds]
  end

  def self.csv_attributes
    %w(base_name distance kind vert_gain vert_loss latitude longitude elevation sub_split_kinds)
  end

  def self.mapping
    {name: :base_name}
  end

  def self.unique_key
    [:course_id, :distance_from_start]
  end
end
