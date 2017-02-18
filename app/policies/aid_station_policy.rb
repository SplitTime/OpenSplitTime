class AidStationPolicy < ApplicationPolicy
  class Scope < Scope
    def post_initialize
    end
  end

  attr_reader :aid_station

  def post_initialize(aid_station)
    @aid_station = aid_station
  end

  def show?
    user.admin?
  end

  def destroy?
    user.authorized_to_edit?(aid_station.event)
  end
end