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

    def google_oauth2
      @user = User.from_omniauth(request.env["omniauth.auth"])

      if @user.persisted?
        sign_in_and_redirect @user, event: :authentication
        set_flash_message(:success, :success, kind: "Google") if is_navigational_format?
      else
        session["devise.google_data"] = request.env["omniauth.auth"].except(:extra) # Removing extra as it can overflow some session stores
        redirect_to new_user_registration_url
      end
    end

    def failure
      case
      when params[:strategy] == "facebook" || request.referrer&.include?("facebook")
        kind = "Facebook"
        reason = params[:error_description]
      when params[:strategy] == "google_oauth2" || request.referrer&.include?("google_oauth2")
        kind = "Google"
        reason = params[:error_description]
      else
        kind = "Unknown"
        reason = params[:error_description] || "Unknown Error"
      end

      set_flash_message(:danger, :failure, kind: kind, reason: reason)
      redirect_to new_user_registration_url
    end
  end
end
