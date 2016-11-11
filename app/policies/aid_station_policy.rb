class AidStationPolicy
  attr_reader :current_user, :aid_station

  def initialize(current_user, aid_station)
    @current_user = current_user
    @aid_station = aid_station
  end

  def show?
    current_user.admin?
  end

  def destroy?
    current_user.authorized_to_edit?(aid_station.event)
  end

end
