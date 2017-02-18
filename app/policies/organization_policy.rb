class OrganizationPolicy < ApplicationPolicy
  class Scope < Scope
    attr_reader :user, :scope

    def post_initialize
    end

    def delegated_records
      scope.joins(:stewardships).where(stewardships: {user_id: user.id})
    end
  end

  attr_reader :organization

  def post_initialize(organization)
    @organization = organization
  end

  def stewards?
    user.authorized_to_edit?(organization)
  end

  def remove_steward?
    user.authorized_to_edit?(organization)
  end

  def post_event_course_org?
    user.authorized_to_edit?(organization)
  end
end