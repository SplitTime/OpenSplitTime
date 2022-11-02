# frozen_string_literal: true

class CourseGroupPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end

    def authorized_to_edit_records
      scope.delegated_to(user)
    end

    def authorized_to_view_records
      scope.visible_or_delegated_to(user)
    end
  end

  attr_reader :course_group

  def post_initialize(course_group)
    @course_group = course_group
  end

  def new?
    course_group.organization && user.authorized_to_edit?(course_group.organization)
  end

  def create?
    course_group.organization && user.authorized_to_edit?(course_group.organization)
  end
end
