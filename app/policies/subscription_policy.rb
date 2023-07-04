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

  def new?
    user.admin? || subscription.user_id == user.id
  end

  def create?
    new?
  end

  def destroy?
    new?
  end

  def refresh?
    new?
  end
end
