class Lotteries::EntrantServiceDetailPolicy < ApplicationPolicy
  def post_initialize(service_detail)
    @lottery_entrant = service_detail.entrant
  end

  def show?
    user.authorized_to_manage_service?(organization, lottery_entrant)
  end

  def edit?
    user.authorized_for_lotteries?(organization)
  end

  def update?
    edit?
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
