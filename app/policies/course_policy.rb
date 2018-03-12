# frozen_string_literal: true

class CoursePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end
  end

  attr_reader :course

  def post_initialize(course)
    @course = course
  end

  # Course destruction could affect events that belong to users other than the course owner
  def destroy?
    user.admin?
  end

  def post_event_course_org?
    user.authorized_to_edit?(course)
  end
end
