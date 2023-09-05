# frozen_string_literal: true

class UserSettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_action
  after_action :verify_authorized

  # GET /user_settings/preferences
  def preferences
    # Need to hang on to flash messages from the subscriptions controller
    flash.keep
  end

  # GET /user_settings/password
  def password
  end

  # GET /user_settings/credentials
  def credentials
    @presenter = UserSettings::CredentialsPresenter.new(current_user)
  end

  # GET /user_settings/credentials_new_service
  def credentials_new_service
    respond_to do |format|
      format.turbo_stream do
        service = Connectors::Service::BY_IDENTIFIER[params[:service_identifier]]
        render :credentials_new_service, locals: { service: service, user: current_user }
      end
    end
  end

  def update
    updated = current_user.update(settings_update_params)
    message = case
              when updated && current_user.unconfirmed_email.present?
                "You have requested that your email address be changed. Please check your email to confirm your new address."
              when updated
                nil
              else
                current_user.errors.full_messages.join("; ")
              end

    redirect_to request.referrer, notice: message
  end

  private

  def authorize_action
    authorize self, policy_class: ::UserSettingsPolicy
  end

  def settings_update_params
    params.require(:user)
      .permit(
        :first_name,
        :last_name,
        :email,
        :phone,
        :pref_distance_unit,
        :pref_elevation_unit,
      )
  end
end
