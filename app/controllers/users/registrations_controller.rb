# https://github.com/plataformatec/devise/wiki/How-To:-redirect-to-a-specific-page-on-successful-sign-in

module Users
  class RegistrationsController < Devise::RegistrationsController

    protected

    def after_sign_up_path_for(resource)
      signed_in_root_path(resource)
    end

    def after_update_path_for(resource)
      signed_in_root_path(resource)
    end

    private

    def sign_up_params
      params.require(:user).permit(*UserParameters.permitted)
    end

    def account_update_params
      params.require(:user).permit(*(UserParameters.permitted << :current_password))
    end
  end
end
