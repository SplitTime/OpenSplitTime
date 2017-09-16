class EventPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end

    def delegated_records
      user ? scope.joins(organization: :stewardships).where(stewardships: {user_id: user.id}) : scope.none
    end
  end

  attr_reader :event

  def post_initialize(event)
    @event = event
  end

  def spread?
    user.authorized_to_edit?(event)
  end

  def import?
    user.authorized_to_edit?(event)
  end

  def import_splits?
    user.authorized_to_edit?(event)
  end

  def import_csv?
    user.authorized_to_edit?(event)
  end

  def import_efforts?
    user.authorized_to_edit?(event)
  end

  def stage?
    user.authorized_to_edit?(event)
  end

  def associate_splits?
    user.authorized_to_edit?(event)
  end

  def remove_splits?
    user.authorized_to_edit?(event)
  end

  def create_people?
    user.authorized_to_edit?(event)
  end

  def reconcile?
    user.authorized_to_edit?(event)
  end

  def delete_all_efforts?
    user.authorized_fully?(event)
  end

  def associate_people?
    user.authorized_to_edit?(event)
  end

  def set_data_status?
    user.authorized_to_edit?(event)
  end

  def set_dropped_attributes?
    user.authorized_to_edit?(event)
  end

  def start_ready_efforts?
    user.authorized_to_edit?(event)
  end

  def live_enable?
    user.authorized_fully?(event)
  end

  def live_disable?
    user.authorized_fully?(event)
  end

  def export_to_ultrasignup?
    user.authorized_to_edit?(event)
  end

  def aid_station_detail?
    user.authorized_to_edit?(event)
  end

  def add_beacon?
    user.authorized_to_edit?(event)
  end

  def find_problem_effort?
    user.authorized_to_edit?(event)
  end

  # Policies for live namespace

  def live_entry?
    user.authorized_to_edit?(event)
  end

  def progress_report?
    user.authorized_to_edit?(event)
  end

  def aid_station_report?
    user.authorized_to_edit?(event)
  end

  def event_data?
    user.authorized_to_edit?(event)
  end

  def live_effort_data?
    user.authorized_to_edit?(event)
  end

  def effort_table?
    user.authorized_to_edit?(event)
  end

  def post_file_effort_data?
    user.authorized_to_edit?(event)
  end

  def set_times_data?
    user.authorized_to_edit?(event)
  end

  def pull_live_time_rows?
    user.authorized_to_edit?(event)
  end

  def trigger_live_times_push?
    user.present?
  end

  # Policies for staging namespace

  def get_countries?
    user.present?
  end

  def get_time_zones?
    user.present?
  end

  def get_locations?
    user.authorized_to_edit?(event)
  end

  def event_staging_app?
    user.authorized_to_edit?(event)
  end

  def post_event_course_org?
    user.authorized_to_edit?(event)
  end

  def update_event_visibility?
    user.authorized_to_edit?(event)
  end

  def new_staging?
    user.present?
  end
end