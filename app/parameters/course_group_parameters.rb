class CourseGroupParameters < BaseParameters
  def self.permitted
    [:id, :name, :slug, :organization_id, {course_ids: []}]
  end
end
