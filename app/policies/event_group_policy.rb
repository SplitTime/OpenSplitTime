class EventGroupPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end

    def delegated_records
      if user
        scope.joins(organization: :stewardships).delegated(user.id)
      else
        scope.none
      end
    end
  end

  attr_reader :event_group

  def post_initialize(event_group)
    @event_group = event_group
  end

  def live_entry?
    user.authorized_to_edit?(event_group)
  end
end
