class UserSettingsController < ApplicationController
  ALLOWED_SUBSCRIBABLE_TYPES = %w[Effort Person].freeze

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

  # GET /user_settings/sms_messaging
  def sms_messaging
    flash.keep
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
    sms_was_opted_in = current_user.sms_opted_in?
    updated = current_user.update(settings_update_params)

    if updated
      flash[:notice] = t("user_settings.update.email_change_requested") if current_user.unconfirmed_email.present?
      handle_sms_consent_change(sms_was_opted_in)
      redirect_to(post_update_redirect_path)
    else
      redirect_to(request.referrer, notice: current_user.errors.full_messages.join("; "))
    end
  end

  private

  def authorize_action
    authorize self, policy_class: ::UserSettingsPolicy
  end

  def handle_sms_consent_change(was_opted_in)
    return if was_opted_in == current_user.sms_opted_in?

    if current_user.sms_opted_in?
      flash[:info] = t("sms.consent.opted_in")
      SmsOptInWelcomeJob.perform_later(current_user)
      create_pending_sms_subscription
    else
      flash[:info] = t("sms.consent.opted_out")
    end
  end

  # If the user arrived from a subscribe-button "Enable texts" link, the form
  # carries the originating subscribable so we can create the subscription
  # in the same round trip and surface the second flash + send the per-effort
  # confirmation SMS without a follow-up click.
  def create_pending_sms_subscription
    subscribable = pending_subscribable
    return if subscribable.nil?
    return if subscribable.subscriptions.exists?(user: current_user, protocol: :sms)

    subscription = subscribable.subscriptions.new(
      user: current_user,
      protocol: :sms,
      endpoint: current_user.sms,
    )

    return unless subscription.save

    # `update` redirects after this method returns, so `flash` (not `flash.now`)
    # is correct — the message needs to persist across the redirect.
    flash[:success] = t("subscriptions.create.success", # rubocop:disable Rails/ActionControllerFlashBeforeRender
                        protocol: "sms",
                        name: subscribable.name,
                        endpoint: subscription.endpoint)
  end

  def pending_subscribable
    type = params[:subscribe_to_type]
    id = params[:subscribe_to_id]
    return nil if type.blank? || id.blank?
    return nil unless ALLOWED_SUBSCRIBABLE_TYPES.include?(type)

    type.constantize.friendly.find(id)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def post_update_redirect_path
    pending_subscribable&.then { |s| polymorphic_path(s) } || request.referrer
  end

  def settings_update_params
    params
      .expect(
        user: [:first_name,
               :last_name,
               :email,
               :phone,
               :sms_consent,
               :pref_distance_unit,
               :pref_elevation_unit],
      )
  end
end
