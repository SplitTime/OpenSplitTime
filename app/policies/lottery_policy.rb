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
    new?
  end

  def create?
    new?
  end

  def update?
    new?
  end

  def destroy?
    new?
  end

  def draw_tickets?
    new?
  end

  def setup?
    new?
  end

  def withdraw_entrants?
    new?
  end

  def export_entrants?
    new?
  end

  def calculations?
    new?
  end

  def sync_calculations?
    new?
  end

  def draw?
    new?
  end

  def delete_draws?
    new?
  end

  def delete_entrants?
    new?
  end

  def attach_service_form?
    new?
  end

  def remove_service_form?
    new?
  end

  def delete_tickets?
    new?
  end

  def generate_entrants?
    new?
  end

  def generate_tickets?
    new?
  end
end
