# frozen_string_literal: true

class OrganizationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    attr_reader :user, :scope

    def post_initialize
    end

    def delegated_records
      user ? scope.joins(:stewardships).where(stewardships: {user_id: user.id}) : scope.none
    end
  end

  attr_reader :organization

  def post_initialize(organization)
    @organization = organization
  end

  def post_event_course_org?
    user.authorized_to_edit?(organization)
  end
end
