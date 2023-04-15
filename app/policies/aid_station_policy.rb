# frozen_string_literal: true

class AidStationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def post_initialize
    end
  end

  attr_reader :aid_station

  def post_initialize(aid_station)
    @aid_station = aid_station
  end

  def create?
    user.authorized_fully?(aid_station.event)
  end

  def destroy?
    create?
  end
end
