# frozen_string_literal: true

class SplitPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
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
