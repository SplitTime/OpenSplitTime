# frozen_string_literal: true

class SplitPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end

    def authorized_to_view_records
      scope.visible_or_delegated_to(user)
    end
  end

  attr_reader :split

  def post_initialize(split)
    @split = split
  end

  def import?
    user.present?
  end
end
