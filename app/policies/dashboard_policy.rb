# frozen_string_literal: true

class DashboardPolicy < Struct.new(:user, :admin)

  def show?
    user.admin?
  end
end
