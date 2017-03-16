class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def index
  end

  def create
    # Raise an error if either participant or user does not exist
    Participant.find(subscription_params[:participant_id])
    User.find(subscription_params[:user_id])

    @subscription = Subscription.new(subscription_params)
    authorize @subscription

    if @subscription.save
      logger.info "Subscription #{@subscription} saved"
    else
      logger.warn "Subscription #{@subscription} not saved"
    end
    render :toggle_email_subscription
  end

  def destroy
    @subscription = Subscription.find(params[:id])
    authorize @subscription

    if @subscription.destroy
      logger.info "Subscription #{@subscription} destroyed"
    else
      logger.warn "Subscription #{@subscription} not destroyed" and return
    end
    render :toggle_email_subscription
  end

  private

  def subscription_params
    params.require(:subscription).permit(*Subscription::PERMITTED_PARAMS)
  end
end