class EventPolicy < ApplicationPolicy
  class Scope < Scope
    def post_initialize
    end

    def delegated_records
      scope.joins(organization: :stewardships).where(stewardships: {user_id: user.id})
    end
  end

  attr_reader :event

  def post_initialize(event)
    @event = event
  end

  def import_splits?
    user.authorized_to_edit?(event)
  end

  def import_efforts?
    user.authorized_to_edit?(event)
  end

  def import_efforts_military_times?
    user.authorized_to_edit?(event)
  end

  def import_efforts_without_times?
    user.authorized_to_edit?(event)
  end

  def stage?
    user.authorized_to_edit?(event)
  end

  def splits?
    user.authorized_to_edit?(event)
  end

  def associate_splits?
    user.authorized_to_edit?(event)
  end

  def remove_splits?
    user.authorized_to_edit?(event)
  end

  def create_participants?
    user.authorized_to_edit?(event)
  end

  def reconcile?
    user.authorized_to_edit?(event)
  end

  def delete_all_efforts?
    user.authorized_to_edit?(event)
  end

  def associate_participants?
    user.authorized_to_edit?(event)
  end

  def set_data_status?
    user.authorized_to_edit?(event)
  end

  def set_dropped_attributes?
    user.authorized_to_edit?(event)
  end

  def start_all_efforts?
    user.authorized_to_edit?(event)
  end

  def live_enable?
    user.authorized_to_edit?(event)
  end

  def live_disable?
    user.authorized_to_edit?(event)
  end

  def export_to_ultrasignup?
    user.authorized_to_edit?(event)
  end

  def aid_station_detail?
    user.authorized_for_live?(event)
  end

  def add_beacon?
    user.authorized_to_edit?(event)
  end

  def find_problem_effort?
    user.authorized_to_edit?(event)
  end

  # Policies for live namespace

  def live_entry?
    user.authorized_for_live?(event)
  end

  def progress_report?
    user.authorized_for_live?(event)
  end

  def aid_station_report?
    user.authorized_for_live?(event)
  end

  def get_event_data?
    user.authorized_for_live?(event)
  end

  def get_live_effort_data?
    user.authorized_for_live?(event)
  end

  def get_effort_table?
    user.authorized_for_live?(event)
  end

  def post_file_effort_data?
    user.authorized_for_live?(event)
  end

  def set_times_data?
    user.authorized_for_live?(event)
  end

  # Policies for staging namespace

  def get_countries?
    user.authorized_for_live?(event)
  end

  def get_courses?
    user.authorized_for_live?(event)
  end

  def get_event?
    user.authorized_for_live?(event)
  end

  def get_locations?
    user.authorized_for_live?(event)
  end

  def get_organizations?
    user.authorized_for_live?(event)
  end

  def event_staging_app?
    user.authorized_for_live?(event)
  end

  def post_event_course_org?
    user.authorized_for_live?(event)
  end
end