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

  # Course destruction could affect events that belong to users other than the course owner
  def destroy?
    user.admin?
  end

  def post_event_course_org?
    user.authorized_to_edit?(event_group)
  end
end
