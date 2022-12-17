# https://github.com/plataformatec/devise/wiki/How-To:-redirect-to-a-specific-page-on-successful-sign-in

module Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :turnstile_verify, only: [:create]

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

    def turnstile_verify
      return if ::OstConfig.cloudflare_turnstile_secret_key.nil?

      token = params[:cf_turnstile_response].to_s
      return if ::Cloudflare::TurnstileVerifier.token_valid?(token)

      redirect_to root_path, notice: "Unauthorized"
    end

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
