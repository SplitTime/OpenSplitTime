# frozen_string_literal: true

class CourseGroupParameters < BaseParameters
  def self.permitted
    [:id, :name, :slug, :organization_id, {course_ids: []}]
  end

  def self.permitted_query
    permitted + EffortParameters.permitted_query
  end
end
