# frozen_string_literal: true

class LiveTimePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end
  end

  attr_reader :live_time

  def post_initialize(live_time)
    @live_time = live_time
  end

  def import?
    user.present?
  end
end
