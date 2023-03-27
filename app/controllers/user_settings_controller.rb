# frozen_string_literal: true

class UserSettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_action
  after_action :verify_authorized

  # GET /preferences
  def preferences
  end

  # GET /password
  def password
  end

  def update
    message = current_user.update(settings_update_params) ? nil : current_user.errors.full_messages.join("; ")

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
            :phone_number,
            :pref_distance_unit,
            :pref_elevation_unit,
          )
  end
end
