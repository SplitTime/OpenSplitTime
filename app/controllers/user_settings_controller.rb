class UserSettingsController < ApplicationController
  SUBSCRIBE_GID_PURPOSE = "sms_opt_in_subscribe".freeze

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
    set_pending_subscribable_warning
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
      set_subscribe_failure_warning
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

  # If the user arrived from a subscribe-button SMS opt-in link, the form
  # carries the originating subscribable so we can create the subscription
  # in the same round trip and surface the second flash + send the per-effort
  # confirmation SMS without a follow-up click.
  def create_pending_sms_subscription
    subscribable = pending_subscribable
    return if subscribable.nil? || subscribable.subscriptions.exists?(user: current_user, protocol: :sms)

    subscription = subscribable.subscriptions.new(
      user: current_user,
      protocol: :sms,
      endpoint: current_user.sms,
    )

    return unless subscription.save

    flash[:success] = t("subscriptions.create.success", # rubocop:disable Rails/ActionControllerFlashBeforeRender
                        protocol: "sms",
                        name: subscribable.name,
                        endpoint: subscription.endpoint)
  end

  def pending_subscribable
    return nil if params[:subscribe_to].blank?

    GlobalID::Locator.locate_signed(params[:subscribe_to], for: SUBSCRIBE_GID_PURPOSE)
  end

  # When the user lands on the SMS settings page from a subscribable's
  # "text" button, surface a flash explaining what they need to fill in
  # to complete the subscription. Skipped if a more specific warning
  # (e.g., the post-save failure warning from `update`) is already present.
  def set_pending_subscribable_warning
    subscribable = pending_subscribable
    return if subscribable.nil? || current_user.sms_opted_in? || flash[:warning].present?

    flash.now[:warning] = t(subscribe_pending_locale_key, name: subscribable.name)
  end

  # Set after the form is submitted: if the user came from a subscribable
  # but didn't end up opted in, the subscription was not created. Tell them
  # what's still missing so they can fix it without leaving the page.
  def set_subscribe_failure_warning
    subscribable = pending_subscribable
    return if subscribable.nil? || current_user.sms_opted_in?

    flash[:warning] = t(subscribe_failed_locale_key, name: subscribable.name) # rubocop:disable Rails/ActionControllerFlashBeforeRender
  end

  def subscribe_pending_locale_key
    if current_user.phone.blank?
      "sms.consent.subscribe_pending_phone_and_consent"
    else
      "sms.consent.subscribe_pending_consent_only"
    end
  end

  def subscribe_failed_locale_key
    if current_user.phone.blank?
      "sms.consent.subscribe_failed_phone_and_consent"
    else
      "sms.consent.subscribe_failed_consent_only"
    end
  end

  def post_update_redirect_path
    if pending_subscribable && current_user.sms_opted_in?
      polymorphic_path(pending_subscribable)
    else
      request.referrer || user_settings_sms_messaging_path
    end
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
