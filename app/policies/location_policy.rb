class LocationPolicy < ApplicationPolicy
  class Scope < Scope
    def post_initialize
    end
  end

  attr_reader :location

  def post_initialize(location)
    @location = location
  end
end