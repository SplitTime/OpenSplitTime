class EffortPolicy
  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @effort = model
  end

  def new?
    @current_user.present?
  end

  def edit?
    @current_user.authorized_to_edit?(@effort)
  end

  def create?
    @current_user.present?
  end

  def update?
    @current_user.authorized_to_edit?(@effort)
  end

  def destroy?
    @current_user.authorized_to_edit?(@effort)
  end

  def associate_participant?
    @current_user.authorized_to_edit?(@effort.event)
  end

  def associate_participants?
    @current_user.authorized_to_edit?(@effort.event)
  end

  def edit_split_times?
    @current_user.authorized_to_edit?(@effort)
  end

end
