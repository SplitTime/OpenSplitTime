# frozen_string_literal: true

class HistoricalFactPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end

    def authorized_to_edit_records
      scope.owned_by(user)
    end

    def authorized_to_view_records
      scope.owned_by(user)
    end
  end

  attr_reader :organization

  def post_initialize(organization)
    verify_authorization_was_delegated(organization, ::HistoricalFact)
    @organization = organization
  end

  def index?
    user.authorized_for_lotteries?(organization)
  end

  def new?
    index?
  end

  def edit?
    index?
  end

  def create?
    index?
  end

  def update?
    index?
  end

  def destroy?
    index?
  end

  def auto_reconcile?
    index?
  end

  def match?
    index?
  end

  def reconcile?
    index?
  end
end
