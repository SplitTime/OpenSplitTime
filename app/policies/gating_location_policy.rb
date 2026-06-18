class GatingLocationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end
  end

  attr_reader :event_group

  def post_initialize(event_group)
    unless event_group.is_a?(::EventGroup)
      raise ::ApplicationPolicy::AuthorizationNotDelegatedError,
            "A GatingLocation must be authorized using the parent EventGroup"
    end

    @event_group = event_group
  end

  def index?
    user.authorized_to_edit?(event_group)
  end

  def new?
    index?
  end

  def create?
    new?
  end

  def edit?
    new?
  end

  def update?
    new?
  end

  def destroy?
    new?
  end
end
