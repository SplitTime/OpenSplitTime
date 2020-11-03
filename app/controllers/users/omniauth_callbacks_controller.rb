# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def facebook
      @user = ::User.from_omniauth(request.env["omniauth.auth"])

      if @user.persisted?
        sign_in_and_redirect @user, event: :authentication
        set_flash_message(:success, :success, kind: "Facebook") if is_navigational_format?
      else
        session["devise.facebook_data"] = request.env["omniauth.auth"].except(:extra) # Removing extra as it can overflow some session stores
        redirect_to new_user_registration_url
      end
    end
  end
end
