class PartnerPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end
  end

  attr_reader :organization

  def post_initialize(organization)
    verify_authorization_was_delegated(organization, ::Partner)
    @organization = organization
  end

  def index?
    user.authorized_to_edit?(organization) || user.authorized_for_lotteries?(organization)
  end

  def new?
    index?
  end

  def create?
    new?
  end

  def edit?
    new?
  end

  def update?
    new?
  end

  def destroy?
    new?
  end
end
