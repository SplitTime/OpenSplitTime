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

  attr_reader :organization

  def post_initialize(organization)
    verify_authorization_was_delegated(organization, ::Lottery)
    @organization = organization
  end

  def new?
    user.authorized_for_lotteries?(organization)
  end

  def edit?
    user.authorized_for_lotteries?(organization)
  end

  def create?
    user.authorized_for_lotteries?(organization)
  end

  def update?
    user.authorized_for_lotteries?(organization)
  end

  def destroy?
    user.authorized_for_lotteries?(organization)
  end

  def draw_tickets?
    user.authorized_for_lotteries?(organization)
  end

  def setup?
    user.authorized_for_lotteries?(organization)
  end

  def export_entrants?
    user.authorized_for_lotteries?(organization)
  end

  def draw?
    user.authorized_for_lotteries?(organization)
  end

  def delete_tickets?
    user.authorized_for_lotteries?(organization)
  end

  def generate_entrants?
    user.authorized_for_lotteries?(organization)
  end

  def generate_tickets?
    user.authorized_for_lotteries?(organization)
  end
end
