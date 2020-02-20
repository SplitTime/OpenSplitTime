module Admin
  class ImpersonateController < Admin::BaseController
    def start
      authorize self
      impersonate_user(User.friendly.find(params[:id]))
      redirect_to root_path
    end

    def stop
      authorize self
      stop_impersonating_user
      redirect_back(fallback_location: root_path)
    end
  end
end
