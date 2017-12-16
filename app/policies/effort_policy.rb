class EffortPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end

    def delegated_records
      if user
        scope.includes(event: {event_group: {organization: :stewardships}}).delegated(user.id)
      else
        scope.none
      end
    end
  end

  attr_reader :effort

  def post_initialize(effort)
    @effort = effort
  end

  def start?
    user.authorized_to_edit?(effort)
  end

  def stop?
    user.authorized_to_edit?(effort)
  end

  def edit_split_times?
    user.authorized_to_edit?(effort)
  end

  def update_split_times?
    user.authorized_to_edit?(effort)
  end

  def delete_split_times?
    user.authorized_to_edit?(effort)
  end

  def set_data_status?
    user.authorized_to_edit?(effort)
  end

  def add_beacon?
    user.authorized_to_edit?(effort)
  end

  def add_report?
    user.authorized_to_edit_personal?(effort)
  end
end