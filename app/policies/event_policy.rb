class EventPolicy
  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @event = model
  end

  def new?
    @current_user.present?
  end

  def import_splits?
    @current_user.authorized_to_edit?(@event)
  end

  def import_efforts?
    @current_user.authorized_to_edit?(@event)
  end

  def edit?
    @current_user.authorized_to_edit?(@event)
  end

  def create?
    @current_user.present?
  end

  def update?
    @current_user.authorized_to_edit?(@event)
  end

  def destroy?
    @current_user.authorized_to_edit?(@event)
  end

  def stage?
    @current_user.authorized_to_edit?(@event)
  end

  def splits?
    @current_user.authorized_to_edit?(@event)
  end

  def associate_split?
    @current_user.authorized_to_edit?(@event)
  end

  def associate_splits?
    @current_user.authorized_to_edit?(@event)
  end

  def remove_split?
    @current_user.authorized_to_edit?(@event)
  end

  def remove_all_splits?
    @current_user.authorized_to_edit?(@event)
  end

  def create_participants?
    @current_user.authorized_to_edit?(@event)
  end

  def reconcile?
    @current_user.authorized_to_edit?(@event)
  end

  def delete_all_efforts?
    @current_user.authorized_to_edit?(@event)
  end

  def associate_participant?
    @current_user.authorized_to_edit?(@event)
  end

  def associate_participants?
    @current_user.authorized_to_edit?(@event)
  end

  def set_data_status?
    @current_user.authorized_to_edit?(@event)
  end

  def live_entry?
    @current_user.admin?
  end

  def live_entry_ajax_get_effort?
    @current_user.admin?
  end

    def live_entry_ajax_get_time_from?
    @current_user.admin?
  end

    def live_entry_ajax_get_time_in_aid?
    @current_user.admin?
  end

    def live_entry_ajax_set_split_times?
    @current_user.admin?
  end

end
