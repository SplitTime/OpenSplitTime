class RawTimePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end
  end

  attr_reader :raw_time

  def post_initialize(raw_time)
    @raw_time = raw_time
  end

  def destroy?
    user.authorized_to_edit?(raw_time.event_group)
  end

  def import?
    user.present?
  end
end
