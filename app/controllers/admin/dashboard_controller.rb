class Admin::DashboardController < Admin::BaseController
  before_action :authenticate_user!
  after_action :verify_authorized

  def dashboard
    authorize :dashboard, :show?
  end

  def flag_split_times
    SplitTime.all.each do |split_time|
      split_time.data_status = 'bad' if split_time.segment_time < 0
    end
    redirect_to admin_root_path
  end

end