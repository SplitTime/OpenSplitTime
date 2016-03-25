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

  def splits?
    @current_user.authorized_to_edit?(@event)
  end

  def associate_split?
    @current_user.authorized_to_edit?(@event)
  end

  def bulk_associate_splits?
    @current_user.authorized_to_edit?(@event)
  end

  def bulk_destroy?
    @current_user.authorized_to_edit?(@event)
  end


end
