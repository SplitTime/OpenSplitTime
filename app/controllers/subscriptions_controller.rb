class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  VALID_SUBSCRIBABLES = Subscription.all_polymorphic_types(:subscribable).map(&:to_s)
  PROTOCOL_WARNINGS = {'sms' => 'Please add a mobile phone number to receive sms text notifications.',
                       'http' => 'Please add an http endpoint to receive http notifications.',
                       'https' => 'Please add an https endpoint to receive https notifications.'}

  def index
  end

  def create
    subscription_params = permitted_params.allow(subscribable_type: VALID_SUBSCRIBABLES).merge(user_id: current_user.id)
    @subscription = Subscription.new(subscription_params)
    authorize @subscription

    if current_user.send(permitted_params[:protocol])
      unless @subscription.save
        logger.warn "  Subscription could not be created: #{@subscription.errors.full_messages}"
      end
      render :toggle_progress_subscription
    else
      flash_protocol_warning
      render :edit_user_endpoints
    end
  end

  def destroy
    @subscription = Subscription.find(params[:id])
    authorize @subscription

    if @subscription.destroy
      logger.info "  #{@subscription} destroyed"
    else
      logger.warn "  #{@subscription} not destroyed" and return
    end
    render :toggle_progress_subscription
  end

  private

  def flash_protocol_warning
    flash[:warning] = PROTOCOL_WARNINGS[permitted_params[:protocol]] || 'Protocol does not exist.'
  end
end
