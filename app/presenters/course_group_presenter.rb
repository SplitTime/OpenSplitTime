class CourseGroupPresenter < BasePresenter
  attr_reader :course_group

  delegate :name, :organization, to: :course_group

  def initialize(course_group, view_context)
    @course_group = course_group || []
    @params = view_context.params
  end

  def organization_name
    organization.name
  end

  def courses
    course_group.courses.sort_by(&:name)
  end

  private

  attr_reader :params
end
