# frozen_string_literal: true

class EventGroupPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end

    def delegated_records
      if user
        scope.joins(organization: :stewardships).includes(organization: :stewardships).delegated(user.id)
      else
        scope.none
      end
    end
  end

  attr_reader :event_group

  def post_initialize(event_group)
    @event_group = event_group
  end

  def raw_times?
    user.authorized_to_edit?(event_group)
  end

  def split_raw_times?
    user.authorized_to_edit?(event_group)
  end

  def roster?
    user.authorized_to_edit?(event_group)
  end

  def delete_all_times?
    user.authorized_fully?(event_group)
  end

  def delete_duplicate_raw_times?
    user.authorized_to_edit?(event_group)
  end

  def set_data_status?
    user.authorized_to_edit?(event_group)
  end

  def start_ready_efforts?
    user.authorized_to_edit?(event_group)
  end

  def update_all_efforts?
    user.authorized_to_edit?(event_group)
  end

  def export_raw_times?
    user.authorized_to_edit?(event_group)
  end

  def live_entry?
    user.authorized_to_edit?(event_group)
  end

  def post_event_course_org?
    user.authorized_to_edit?(event_group)
  end

  def import?
    user.authorized_to_edit?(event_group)
  end

  def trigger_raw_times_push?
    user.present?
  end

  def pull_raw_times?
    user.authorized_to_edit?(event_group)
  end

  def enrich_raw_time_row?
    user.present?
  end

  def import_csv_raw_times?
    user.authorized_to_edit?(event_group)
  end

  def submit_raw_time_rows?
    user.authorized_to_edit?(event_group)
  end

  def pull_time_record_rows?
    user.authorized_to_edit?(event_group)
  end

  def not_expected?
    user.authorized_to_edit?(event_group)
  end
end
