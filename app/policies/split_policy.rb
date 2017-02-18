class SplitPolicy < ApplicationPolicy
  class Scope < Scope
    def post_initialize
    end
  end

  attr_reader :split

  def post_initialize(split)
    @split = split
  end

  def destroy?
    user.admin?
  end

  def import?
    user.present?
  end

  def create_location?
    user.authorized_to_edit?(split)
  end

  def assign_location?
    user.authorized_to_edit?(split)
  end
end