class ParticipantPolicy < ApplicationPolicy
  class Scope < Scope
    def post_initialize
    end
  end

  attr_reader :participant

  def post_initialize(participant)
    @participant = participant
  end

  def new?
    user.admin?
  end

  def create?
    user.admin?
  end

  def destroy?
    user.admin?
  end

  def avatar_claim?
    user.authorized_to_claim?(participant)
  end

  def avatar_disclaim?
    user.admin?
  end

  def merge?
    user.admin?
  end

  def combine?
    user.admin?
  end

  def remove_effort?
    user.admin?
  end
end