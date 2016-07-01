class RacePolicy
  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @race = model
  end

  def new?
    @current_user.present?
  end

  def edit?
    @current_user.authorized_to_edit?(@race)
  end

  def create?
    @current_user.present?
  end

  def update?
    @current_user.authorized_to_edit?(@race)
  end

  def destroy?
    @current_user.authorized_to_edit?(@race)
  end

  def stewards?
    @current_user.authorized_to_edit?(@race)
  end

  def remove_steward?
    @current_user.authorized_to_edit?(@race)
  end

end
