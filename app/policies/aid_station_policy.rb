# frozen_string_literal: true

class AidStationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end
  end

  attr_reader :organization

  def post_initialize(organization)
    verify_authorization_was_delegated(organization, ::AidStation)
    @organization = organization
  end

  def create?
    user.authorized_fully?(organization)
  end

  def destroy?
    create?
  end
end
