class SplitTimePolicy < ApplicationPolicy
  class Scope < Scope
    def post_initialize
    end
  end

  attr_reader :split_time

  def post_initialize(split_time)
    @split_time = split_time
  end

  def import?
    user.present?
  end
end