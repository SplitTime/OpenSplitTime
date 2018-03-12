# frozen_string_literal: true

class SubscriptionPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end
  end

  attr_reader :subscription

  def post_initialize(subscription)
    @subscription = subscription
  end

  def create?
    user.admin? || subscription.user_id == user.id
  end

  def destroy?
    user.admin? || subscription.user_id == user.id
  end
end
