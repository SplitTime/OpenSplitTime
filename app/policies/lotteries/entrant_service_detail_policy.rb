# frozen_string_literal: true

class Lotteries::EntrantServiceDetailPolicy < ApplicationPolicy
  def post_initialize(service_detail)
    @lottery_entrant = service_detail.entrant
  end

  def show?
    user.email == lottery_entrant.email || user.authorized_for_lotteries?(organization)
  end

  def attach_completed_form?
    show?
  end

  def download_completed_form?
    show?
  end

  def remove_completed_form?
    show?
  end

  private

  attr_reader :lottery_entrant
  delegate :organization, to: :lottery_entrant, private: true
end
