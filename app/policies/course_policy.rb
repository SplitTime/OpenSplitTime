# frozen_string_literal: true

class CoursePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end

    def authorized_to_edit_records
      scope.owned_by(user)
    end

    def authorized_to_view_records
      scope.visible_or_delegated_to(user)
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
