# frozen_string_literal: true

class StewardshipPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end
  end

  attr_reader :stewardship

  def post_initialize(stewardship)
    @stewardship = stewardship
  end

  def create?
    user.admin? || user.authorized_fully?(stewardship.organization)
  end

  def destroy?
    user.admin? || user.authorized_fully?(stewardship.organization)
  end
end
