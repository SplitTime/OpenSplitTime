# frozen_string_literal: true

class EffortPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end

    def authorized_to_edit_records
      scope.delegated_to(user)
    end

    def authorized_to_view_records
      scope.visible_or_delegated_to(user)
    end
  end

  attr_reader :effort

  def post_initialize(effort)
    @effort = effort
  end

  def audit?
    user.authorized_to_edit?(effort)
  end

  def unstart?
    user.authorized_to_edit?(effort)
  end

  def rebuild?
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

  def with_times_row?
    user.present?
  end
end
