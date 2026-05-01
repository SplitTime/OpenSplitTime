module Users
  class SessionsController < Devise::SessionsController
    REASON_ALERTS = {
      "subscribe" => "subscriptions.toggle.sign_in_required",
    }.freeze

    SUBSCRIBE_GID_PURPOSE = "subscribe_after_signin".freeze

    def new
      flash.now[:alert] = t(REASON_ALERTS[params[:reason]]) if REASON_ALERTS.key?(params[:reason])

      respond_to do |format|
        format.html { super }
        format.turbo_stream do
          user = User.new(email: params.dig(:user, :email))
          locals = { resource: user, resource_name: :user }
          render turbo_stream: turbo_stream.replace("form_modal", partial: "devise/sessions/form", locals: locals)
        end
      end
    end

    def create
      resource = warden.authenticate!(auth_options)
      resource_or_scope = resource_name
      scope = Devise::Mapping.find_scope!(resource_or_scope)
      resource ||= resource_or_scope

      return unless sign_in(scope, resource)

      clear_oauth_provider(resource) if resource.provider.present? || resource.uid.present?

      render turbo_stream: post_signin_streams
    end

    private

    # On a successful sign in using database authentication, we want to remove
    # omniauth provider and uid from the user record
    def clear_oauth_provider(resource)
      resource.update(provider: nil, uid: nil)
    end

    # Resolves the subscribe-intent (if any) carried through from the
    # subscribe-button login modal, then returns the appropriate
    # turbo-stream(s) to render.
    #
    # Three outcomes when the intent is present and well-formed:
    #
    # 1. Email subscribe, or SMS subscribe by an already-opted-in user —
    #    create the subscription inline; respond with the navbar swap so the
    #    modal closes and the page reloads to reflect subscribed state.
    # 2. SMS subscribe by a user who hasn't yet provided phone + consent —
    #    don't try to subscribe; respond with a `visit` stream that hands
    #    the user off to the streamlined SMS opt-in flow at
    #    /user_settings/sms_messaging?subscribe_to=<sgid>, which finishes
    #    the subscription after they save phone + consent.
    # 3. Tampered/expired/invalid intent — fall through to the standard
    #    navbar-only response (user is logged in but no subscribe action
    #    fired). Same as no intent at all.
    def post_signin_streams
      navbar_stream = turbo_stream.replace("ost_navbar", partial: "layouts/navigation")
      return navbar_stream unless subscribe_intent_present?

      subscribable = pending_subscribable
      return navbar_stream if subscribable.nil?

      protocol = params[:notification_protocol]
      case protocol
      when "email"
        create_pending_subscription(subscribable, "email")
        navbar_stream
      when "sms"
        if current_user.sms_opted_in?
          create_pending_subscription(subscribable, "sms")
          navbar_stream
        else
          # Hand off to the streamlined SMS opt-in flow built in PR #1974.
          # That flow's UserSettingsController#pending_subscribable expects the
          # SGID to be signed for "sms_opt_in_subscribe", whereas the inbound
          # `params[:subscribe_to]` here was signed for "subscribe_after_signin".
          # Re-encode for the downstream purpose so the locator there resolves.
          handoff_sgid = subscribable.to_signed_global_id(for: "sms_opt_in_subscribe").to_s
          navbar_stream + visit_stream(user_settings_sms_messaging_path(subscribe_to: handoff_sgid))
        end
      else
        navbar_stream
      end
    end

    def subscribe_intent_present?
      params[:subscribe_to].present?
    end

    def pending_subscribable
      GlobalID::Locator.locate_signed(params[:subscribe_to], for: SUBSCRIBE_GID_PURPOSE)
    end

    def create_pending_subscription(subscribable, protocol)
      return if subscribable.subscriptions.exists?(user: current_user, protocol: protocol)

      endpoint = protocol == "email" ? current_user.email : current_user.sms
      subscription = subscribable.subscriptions.new(
        user: current_user,
        protocol: protocol,
        endpoint: endpoint,
      )
      return unless subscription.save

      flash_key = protocol == "sms" ? "subscriptions.create.success" : "subscriptions.create.pending_confirmation"
      # Persistent flash so it survives the modal-close + page reload.
      flash[:success] = t(flash_key,
                          protocol: protocol,
                          name: subscribable.name,
                          endpoint: subscription.endpoint)
    end

    def visit_stream(path)
      helpers.tag.turbo_stream(action: "visit", href: path)
    end
  end
end
