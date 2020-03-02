module Admin
  class DashboardController < Admin::BaseController
    def show
      authorize :dashboard, policy_class: Admin::DashboardPolicy
    end
  end
end
