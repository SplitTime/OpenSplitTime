# frozen_string_literal: true

class OrganizationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end

    def authorized_to_edit_records
      scope.owned_by(user)
    end

    def authorized_to_view_records
      scope.visible_or_authorized_for(user)
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
