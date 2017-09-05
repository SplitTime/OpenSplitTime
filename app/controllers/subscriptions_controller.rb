class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def index
  end

  def create
    # Raise an error if either person or user does not exist
    Person.friendly.find(permitted_params[:person_id])
    user = User.friendly.find(permitted_params[:user_id])

    @subscription = Subscription.new(permitted_params)
    authorize @subscription

    if user.send(permitted_params[:protocol])
      if @subscription.save
        logger.info "#{@subscription} saved"
      else
        logger.warn "#{@subscription} not saved"
      end
      render :toggle_email_subscription
    else
      flash_protocol_warning
      render :edit_user_endpoints
    end
  end

  def destroy
    @subscription = Subscription.find(params[:id])
    authorize @subscription

    if @subscription.destroy
      logger.info "#{@subscription} destroyed"
    else
      logger.warn "#{@subscription} not destroyed" and return
    end
    render :toggle_email_subscription
  end

  private

  def flash_protocol_warning
    case permitted_params[:protocol]
    when 'sms'
      flash[:warning] = 'Please add a mobile phone number to receive sms text notifications.'
    when 'http'
      flash[:warning] = 'Please add an http endpoint to receive http notifications.'
    when 'https'
      flash[:warning] = 'Please add an https endpoint to receive https notifications.'
    else
      flash[:warning] = 'Protocol does not exist.'
    end
  end
end
