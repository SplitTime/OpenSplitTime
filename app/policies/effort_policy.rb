class EffortPolicy
  attr_reader :current_user, :effort

  def initialize(current_user, effort)
    @current_user = current_user
    @effort = effort
  end

  def new?
    current_user.present?
  end

  def edit?
    current_user.authorized_to_edit?(effort)
  end

  def create?
    current_user.present?
  end

  def update?
    current_user.authorized_to_edit?(effort)
  end

  def destroy?
    current_user.authorized_to_edit?(effort)
  end

  def analyze?
    current_user.present?
  end

  def place?
    current_user.present?
  end

  def associate_participants?
    current_user.authorized_to_edit?(effort.event)
  end

  def start?
    current_user.authorized_to_edit?(effort)
  end

  def edit_split_times?
    current_user.authorized_to_edit?(effort)
  end

  def delete_split_times?
    current_user.authorized_to_edit?(effort)
  end

  def confirm_split_times?
    current_user.authorized_to_edit?(effort)
  end

  def set_data_status?
    current_user.authorized_to_edit?(effort)
  end

  def add_beacon?
    current_user.authorized_to_edit?(effort)
  end

  def add_report?
    current_user.authorized_to_edit_personal?(effort)
  end

  def add_photo?
    current_user.authorized_to_edit?(effort)
  end

end
