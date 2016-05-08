class Admin::DashboardController < Admin::BaseController
  before_action :authenticate_user!
  after_action :verify_authorized, only: :dashboard

  def dashboard
    authorize :dashboard, :show?
  end

  def set_effort_ages
    efforts = Effort.where.not(birthdate: nil).where(age: nil)
    if efforts.count > 0
      update_count = efforts.reset_effort_ages
      flash[:success] = "Set ages for #{update_count} efforts."
    else
      flash[:warning] = "No efforts contained birthdates without ages."
    end
    redirect_to admin_root_path
  end

end