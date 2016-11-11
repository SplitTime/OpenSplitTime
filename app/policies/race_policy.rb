class RacePolicy
  attr_reader :current_user, :race

  def initialize(current_user, race)
    @current_user = current_user
    @race = race
  end

  def new?
    current_user.present?
  end

  def edit?
    current_user.authorized_to_edit?(race)
  end

  def create?
    current_user.present?
  end

  def update?
    current_user.authorized_to_edit?(race)
  end

  def destroy?
    current_user.authorized_to_edit?(race)
  end

  def stewards?
    current_user.authorized_to_edit?(race)
  end

  def remove_steward?
    current_user.authorized_to_edit?(race)
  end

end
