class LocationPolicy
  attr_reader :current_user, :location

  def initialize(current_user, location)
    @current_user = current_user
    @location = location
  end

  def new?
    current_user.present?
  end

  def edit?
    current_user.authorized_to_edit?(location)
  end

  def create?
    current_user.present?
  end

  def update?
    current_user.authorized_to_edit?(location)
  end

  def destroy?
    current_user.authorized_to_edit?(location)
  end

end
