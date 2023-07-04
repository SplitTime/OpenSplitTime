# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_subscribable
  before_action :set_subscription, except: [:new, :create]
  after_action :verify_authorized

  def new
    @subscription = @subscribable.subscriptions.new(user: current_user)
    authorize @subscription
  end

  def create
    @subscription = @subscribable.subscriptions.new(permitted_params)
    @subscription.user = current_user
    protocol = permitted_params[:protocol]
    @subscription.endpoint = case protocol
                             when "email" then current_user.email
                             when "sms" then current_user.sms
                             else params.dig(:subscription, :endpoint)
                             end
    authorize @subscription

    if protocol == "sms" && current_user.sms.blank?
      flash[:warning] = "Please add a mobile phone number to receive sms text notifications."
      redirect_to user_settings_preferences_path
    elsif @subscription.save
      flash.now[:success] = "You have subscribed to #{protocol} notifications for #{@subscribable.name}. " +
        "Messages will be sent to #{@subscription[:endpoint]}."
      render "replace_button", locals: { subscribable: @subscribable, protocol: protocol }
    else
      flash.now[:danger] = @subscription.errors.full_messages.to_sentence
      render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash")
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

  def set_subscribable
    raise NotImplementedError, "set_subscribable must be implemented"
  end

  def set_subscription
    @subscription = @subscribable.subscriptions.find(params[:id])
  end
end
