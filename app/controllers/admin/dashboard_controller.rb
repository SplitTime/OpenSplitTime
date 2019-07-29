class Admin::DashboardController < Admin::BaseController
  before_action :authenticate_user!
  after_action :verify_authorized, only: :dashboard

  def dashboard
    authorize :dashboard, :show?
  end

  def impersonate
    return unless current_user&.admin?
    impersonate_user(User.friendly.find(params[:id]))
    redirect_to root_path
  end

  def stop_impersonating
    stop_impersonating_user
    redirect_back(fallback_location: root_path)
  end
end
