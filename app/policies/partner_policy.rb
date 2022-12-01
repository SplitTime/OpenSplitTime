# frozen_string_literal: true

class PartnerPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end
  end

  attr_reader :partner

  def post_initialize(partner)
    @partner = partner
  end

  def new?
    user.authorized_to_edit?(partner.partnerable) || user.authorized_for_lotteries?(partner.partnerable)
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
