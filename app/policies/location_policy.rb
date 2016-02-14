class LocationPolicy
  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @location = model
  end

  def new?
    @current_user.present?
  end

  def edit?
    @current_user.authorized_to_edit?(@location)
  end

  def create?
    @current_user.present?
  end

  def update?
    @current_user.authorized_to_edit?(@location)
  end

  def destroy?
    @current_user.authorized_to_edit?(@location)
  end

end
