class LotterySimulationRunPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end
  end

  attr_reader :organization

  def post_initialize(organization)
    verify_authorization_was_delegated(organization, ::LotterySimulationRun)
    @organization = organization
  end

  def index?
    user.authorized_for_lotteries?(organization)
  end

  def show?
    user.authorized_for_lotteries?(organization)
  end

  def new?
    user.authorized_for_lotteries?(organization)
  end

  def create?
    user.authorized_for_lotteries?(organization)
  end

  def destroy?
    user.authorized_for_lotteries?(organization)
  end
end
