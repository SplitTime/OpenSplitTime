class EventGroupPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end

    def delegated_records
      user ? scope.joins(organization: :stewardships).where(stewardships: {user_id: user.id}) : scope.none
    end
  end

  attr_reader :event_group

  def post_initialize(event_group)
    @event_group = event_group
  end
end
