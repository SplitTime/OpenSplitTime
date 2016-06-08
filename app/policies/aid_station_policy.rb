class AidStationPolicy
  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @event_split = model
  end

  def show?
    @current_user.admin?
  end

  def destroy?
    @current_user.authorized_to_edit?(@aid_station.event)
  end

end
