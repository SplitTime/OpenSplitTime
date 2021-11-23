# frozen_string_literal: true

module Admin
  class DashboardPolicy < ApplicationPolicy
    def post_initialize(_record)
    end

    def show?
      user.admin?
    end

    def timeout?
      user.admin?
    end
  end
end
