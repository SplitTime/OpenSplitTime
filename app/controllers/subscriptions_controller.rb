# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_subscribable
  before_action :set_subscription, except: [:create]
  after_action :verify_authorized

  PROTOCOL_WARNINGS = {
    "sms" => "Please add a mobile phone number to receive sms text notifications.",
    "http" => "Please add an http endpoint to receive http notifications.",
    "https" => "Please add an https endpoint to receive https notifications.",
  }.freeze

  def create
    @subscription = @subscribable.subscriptions.new(permitted_params)
    @subscription.user = current_user
    protocol = permitted_params[:protocol]
    authorize @subscription

    if current_user.send(protocol)
      @subscription.save!
      render "replace_button", locals: { subscribable: @subscribable, protocol: protocol }
    else
      flash_protocol_warning
      redirect_to user_settings_preferences_path(current_user)
    end
  end

  def destroy
    @subscription = @subscribable.subscriptions.find(params[:id])
    protocol = @subscription.protocol
    authorize @subscription

    @subscription.destroy
    render "replace_button", locals: { subscribable: @subscribable, protocol: protocol }
  end

  private

  def flash_protocol_warning
    flash[:warning] = PROTOCOL_WARNINGS[permitted_params[:protocol]] || "Protocol does not exist."
  end

  def set_subscribable
    raise NotImplementedError, "set_subscribable must be implemented"
  end

  def set_subscription
    @subscription = @subscribable.subscriptions.find(params[:id])
  end
end
