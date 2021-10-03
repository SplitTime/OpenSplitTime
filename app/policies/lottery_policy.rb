# frozen_string_literal: true

class LotteryPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end

    def authorized_to_edit_records
      scope.owned_by(user)
    end

    def authorized_to_view_records
      scope.visible_or_delegated_to(user)
    end
  end

  attr_reader :lottery

  def post_initialize(lottery)
    @lottery = lottery
  end

  def new?
    user.authorized_for_lotteries?(lottery)
  end

  def edit?
    user.authorized_for_lotteries?(lottery)
  end

  def create?
    user.authorized_for_lotteries?(lottery)
  end

  def update?
    user.authorized_for_lotteries?(lottery)
  end

  def destroy?
    user.authorized_for_lotteries?(lottery)
  end

  def admin?
    user.authorized_for_lotteries?(lottery)
  end

  def draw?
    user.authorized_for_lotteries?(lottery)
  end
end
