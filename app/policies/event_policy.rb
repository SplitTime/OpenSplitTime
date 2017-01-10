class EventPolicy
  attr_reader :current_user, :event

  def initialize(current_user, event)
    @current_user = current_user
    @event = event
  end

  def new?
    current_user.present?
  end

  def import_splits?
    current_user.authorized_to_edit?(event)
  end

  def import_efforts?
    current_user.authorized_to_edit?(event)
  end

  def import_efforts_without_times?
    current_user.authorized_to_edit?(event)
  end

  def edit?
    current_user.authorized_to_edit?(event)
  end

  def create?
    current_user.present?
  end

  def update?
    current_user.authorized_to_edit?(event)
  end

  def destroy?
    current_user.authorized_to_edit?(event)
  end

  def stage?
    current_user.authorized_to_edit?(event)
  end

  def splits?
    current_user.authorized_to_edit?(event)
  end

  def associate_split?
    current_user.authorized_to_edit?(event)
  end

  def associate_splits?
    current_user.authorized_to_edit?(event)
  end

  def remove_splits?
    current_user.authorized_to_edit?(event)
  end

  def create_participants?
    current_user.authorized_to_edit?(event)
  end

  def reconcile?
    current_user.authorized_to_edit?(event)
  end

  def delete_all_efforts?
    current_user.authorized_to_edit?(event)
  end

  def associate_participants?
    current_user.authorized_to_edit?(event)
  end

  def set_data_status?
    current_user.authorized_to_edit?(event)
  end

  def set_dropped_attributes?
    current_user.authorized_to_edit?(event)
  end

  def start_all_efforts?
    current_user.authorized_to_edit?(event)
  end

  def live_enable?
    current_user.authorized_to_edit?(event)
  end

  def live_disable?
    current_user.authorized_to_edit?(event)
  end

  def export_to_ultrasignup?
    current_user.authorized_to_edit?(event)
  end

  # Policies for live namespace

  def live_entry?
    current_user.authorized_for_live?(event)
  end

  def progress_report?
    current_user.authorized_for_live?(event)
  end

  def aid_station_report?
    current_user.authorized_for_live?(event)
  end

  def get_event_data?
    current_user.authorized_for_live?(event)
  end

  def get_live_effort_data?
    current_user.authorized_for_live?(event)
  end

  def get_effort_table?
    current_user.authorized_for_live?(event)
  end

  def post_file_effort_data?
    current_user.authorized_for_live?(event)
  end

  def set_times_data?
    current_user.authorized_for_live?(event)
  end

  def aid_station_degrade?
    current_user.authorized_for_live?(event)
  end

  def aid_station_advance?
    current_user.authorized_for_live?(event)
  end

  def aid_station_detail?
    current_user.authorized_for_live?(event)
  end

  def add_beacon?
    current_user.authorized_to_edit?(event)
  end

end
