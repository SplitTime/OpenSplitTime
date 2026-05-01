module Users
  class SessionsController < Devise::SessionsController
    REASON_ALERTS = {
      "subscribe" => "subscriptions.toggle.sign_in_required",
    }.freeze

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
      render turbo_stream: turbo_stream.replace("ost_navbar", partial: "layouts/navigation")
    end

    private

    # On a successful sign in using database authentication, we want to remove
    # omniauth provider and uid from the user record
    def clear_oauth_provider(resource)
      resource.update(provider: nil, uid: nil)
    end
  end
end
