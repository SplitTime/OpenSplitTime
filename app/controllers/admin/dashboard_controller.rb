module Admin
  class DashboardController < Admin::BaseController
    def dashboard
      authorize :dashboard, :show?
    end
  end
end
