class EffortPolicy < ApplicationPolicy
  class Scope < Scope
    def post_initialize
    end

    def delegated_records
      scope.joins(event: {organization: :stewardships}).where(stewardships: {user_id: user.id})
    end
  end

  attr_reader :effort

  def post_initialize(effort)
    @effort = effort
  end

  def analyze?
    true
  end

  def place?
    true
  end

  def associate_participants?
    user.authorized_to_edit?(effort.event)
  end

  def start?
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

  def confirm_split_times?
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

  def add_photo?
    user.authorized_to_edit?(effort)
  end
end