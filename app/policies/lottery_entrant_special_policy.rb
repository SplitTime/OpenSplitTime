# frozen_string_literal: true

class LotteryEntrantSpecialPolicy < ApplicationPolicy
  attr_reader :lottery_entrant, :organization

  def post_initialize(lottery_entrant)
    @lottery_entrant = lottery_entrant
    @organization = lottery_entrant.organization
  end

  def manage_service?
    user.email == @lottery_entrant.email || user.authorized_for_lotteries?(@organization)
  end
end
