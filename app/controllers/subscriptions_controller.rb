# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_subscribable
  before_action :set_subscription, except: [:create]
  after_action :verify_authorized

  PROTOCOL_WARNINGS = {
    "sms" => "Please add a mobile phone number to receive sms text notifications.",
  }.freeze

  def create
    @subscription = @subscribable.subscriptions.new(permitted_params)
    @subscription.user = current_user
    protocol = permitted_params[:protocol]
    @subscription.endpoint = case protocol
                             when "email"
                               current_user.email
                             when "sms"
                               current_user.sms
                             when "http", "https"
                               params[:endpoint]
                             else
                               nil
                             end
    authorize @subscription

    if @subscription.endpoint.present?
      if @subscription.save
        flash.now[:success] = "You have subscribed to #{protocol} notifications for #{@subscribable.full_name}. " +
          "Messages will be sent to #{@subscription[:endpoint]}."
        render "replace_button", locals: { subscribable: @subscribable, protocol: protocol }
      else
        flash.now[:danger] = @subscription.errors.full_messages.to_sentence
        render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash")
      end
    else
      flash_protocol_warning
      redirect_to user_settings_preferences_path
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
