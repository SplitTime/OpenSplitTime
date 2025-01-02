class ConnectionPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end
  end

  attr_reader :organization

  def post_initialize(organization)
    verify_authorization_was_delegated(organization, ::Connection)
    @organization = organization
  end

  def index?
    user.authorized_to_edit?(organization) || user.authorized_for_lotteries?(organization)
  end

  def new?
    index?
  end

  def create?
    index?
  end

  def destroy?
    index?
  end
end
