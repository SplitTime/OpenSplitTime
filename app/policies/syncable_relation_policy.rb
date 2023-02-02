# frozen_string_literal: true

class SyncableRelationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end
  end

  attr_reader :organization

  def post_initialize(organization)
    verify_authorization_was_delegated(organization, ::SyncableRelation)
    @organization = organization
  end

  def create?
    user.authorized_to_edit?(organization) || user.authorized_for_lotteries?(organization)
  end

  def destroy?
    create?
  end
end
