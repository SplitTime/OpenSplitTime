# https://github.com/plataformatec/devise/wiki/How-To:-redirect-to-a-specific-page-on-successful-sign-in

module Users
  class RegistrationsController < Devise::RegistrationsController

    # GET /resource/sign_up
    def new
      build_resource(pre_filled_params)
      yield resource if block_given?
      respond_with resource
    end

    protected

    def after_sign_up_path_for(resource)
      signed_in_root_path(resource)
    end

    def after_update_path_for(resource)
      signed_in_root_path(resource)
    end

    private

    def pre_filled_params
      params[:user]&.permit(*UserParameters.permitted) || {}
    end

    def sign_up_params
      params.require(:user).permit(*UserParameters.permitted)
    end

    def account_update_params
      params.require(:user).permit(*(UserParameters.permitted << :current_password))
    end
  end
end
