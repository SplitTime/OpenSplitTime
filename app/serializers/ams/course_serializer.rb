# frozen_string_literal: true

class CourseSerializer < BaseSerializer
  attributes :id, :name, :description, :editable, :locations, :track_points
  link(:self) { api_v1_course_path(object) }

  has_many :splits
  belongs_to :organization

  def locations
    object.ordered_splits.select(&:has_location?).map do |split|
      {id: split.id, base_name: split.base_name, latitude: split.latitude, longitude: split.longitude}
    end
  end
end
