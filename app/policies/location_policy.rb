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
    @current_user.admin?
  end

  def create?
    @current_user.present?
  end

  def update?
    @current_user.admin?
  end

  def destroy?
    @current_user.admin?
  end

end
