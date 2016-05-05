class Admin::DashboardController < Admin::BaseController
  before_action :authenticate_user!
  after_action :verify_authorized

  def dashboard
    authorize :dashboard, :show?
  end

end