module Admin
  class ImpersonateController < Admin::BaseController
    after_action :verify_authorized, except: [:start, :stop]

    def start
      return unless current_user.admin?

      impersonate_user(User.friendly.find(params[:id]))
      redirect_to root_path
    end

    def stop
      stop_impersonating_user
      redirect_back(fallback_location: root_path)
    end
  end
end
