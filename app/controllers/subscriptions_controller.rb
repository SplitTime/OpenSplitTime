class SubscriptionsController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :authenticate_user!
  before_action :set_subscribable
  before_action :set_subscription, except: [:new, :create]
  after_action :verify_authorized

  # GET /subscribable/:subscribable_id/subscriptions/new
  def new
    @subscription = @subscribable.subscriptions.new(user: current_user)
    authorize @subscription

    render :new, locals: { subscription: @subscription }
  end

  # POST /subscribable/:subscribable_id/subscriptions
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
      render :create, locals: { subscription: @subscription, subscribable: @subscribable, protocol: protocol }
    else
      if @subscription.subscribable.is_a?(Event)
        render :new, locals: { subscription: @subscription }, status: :unprocessable_entity
      else
        flash.now[:danger] = @subscription.errors.full_messages.to_sentence
        render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash")
      end
    end
  end

  # DELETE /subscribable/:subscribable_id/subscriptions/:id
  def destroy
    authorize @subscription
    protocol = @subscription.protocol

    @subscription.destroy

    render "destroy", locals: { subscription: @subscription, subscribable: @subscribable, protocol: protocol }
  end

  # PATCH /subscribable/:subscribable_id/subscriptions/:id/refresh
  def refresh
    authorize @subscription

    if @subscription.save
      @subscription.touch
      flash.now[:success] = "Subscription was refreshed."
    else
      flash.now[:danger] = "Subscription could not be refreshed." + @subscription.errors.full_messages.to_sentence
    end

    render :refresh, locals: { subscription: @subscription }
  end

  private

  def set_subscribable
    raise NotImplementedError, "set_subscribable must be implemented"
  end

  def set_subscription
    @subscription = @subscribable.subscriptions.find(params[:id])
  end
end
