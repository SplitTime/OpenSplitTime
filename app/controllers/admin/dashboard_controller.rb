module Admin
  class DashboardController < Admin::BaseController
    def show
      authorize :dashboard, policy_class: Admin::DashboardPolicy
    end

    def timeout
      authorize :timeout, policy_class: Admin::DashboardPolicy

      Rails.logger.info "Sleeping for 35 seconds to produce an intentional timeout"
      sleep 35
      Rails.logger.info "Done sleeping"

      redirect_to admin_dashboard_path
    end
  end
end
