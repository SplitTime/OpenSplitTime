class PartnerAdPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end
  end

  attr_reader :partner_ad

  def post_initialize(partner_ad)
    @partner_ad = partner_ad
  end

  def create?
    user.authorized_to_edit?(partner_ad.event)
  end

  def edit?
    user.authorized_to_edit?(partner_ad.event)
  end

  def update?
    user.authorized_to_edit?(partner_ad.event)
  end

  def destroy?
    user.authorized_to_edit?(partner_ad.event)
  end
end
