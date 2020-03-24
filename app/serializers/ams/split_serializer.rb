# frozen_string_literal: true

class SplitSerializer < BaseSerializer
  attributes :id, :course_id, :distance_from_start, :vert_gain_from_start, :vert_loss_from_start,
             :kind, :base_name, :name_extensions, :sub_split_kinds, :description, :latitude, :longitude, :elevation, :editable
  link(:self) { api_v1_split_path(object) }

  belongs_to :course

  def sub_split_kinds
    object.name_extensions
  end
end
