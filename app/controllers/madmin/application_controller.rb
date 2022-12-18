module Madmin
  class ApplicationController < Madmin::BaseController
    before_action :authenticate_admin_user

    def authenticate_admin_user
      redirect_to "/", alert: "Not authorized." unless user_signed_in? && current_user.admin?
    end
  end
end
