class Admin::DashboardController < Admin::BaseController
  before_action :authenticate_user!
  after_action :verify_authorized, only: :dashboard

  def dashboard
    authorize :dashboard, :show?
  end
end