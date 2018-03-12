# frozen_string_literal: true

class SplitTimePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end
  end

  attr_reader :split_time

  # SplitTime will almost always be created via event effort import, live entry, or effort update split times.
  # Requiring admin authority to create or update a split_time via Api::V1::SplitTimesController#create avoids the possibility
  # for vandalism by the creation of confusing data.

  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def post_initialize(split_time)
    @split_time = split_time
  end

  def import?
    user.present?
  end
end
