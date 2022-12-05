# frozen_string_literal: true

class StewardshipPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end
  end

  attr_reader :organization

  def post_initialize(organization)
    verify_authorization_was_delegated(organization, ::Stewardship)
    @organization = organization
  end

  def index?
    user.admin? || user.authorized_fully?(organization)
  end

  def create?
    index?
  end

  def update?
    create?
  end

  def destroy?
    create?
  end
end
