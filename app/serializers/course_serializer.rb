# frozen_string_literal: true

class CourseSerializer < BaseSerializer
  attributes :id, :name, :description, :editable
  link(:self) { api_v1_course_path(object) }

  has_many :splits
end
