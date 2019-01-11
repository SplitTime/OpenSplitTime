# https://github.com/plataformatec/devise/wiki/How-To:-redirect-to-a-specific-page-on-successful-sign-in

module Users
  class SessionsController < Devise::SessionsController
    def new
      redirect_to root_path
    end

    def create
      resource = warden.authenticate!(scope: resource_name, recall: "#{controller_path}#log_in_failure")
      sign_in_and_redirect(resource_name, resource)
    end

    # If status is 401, Devise will redirect to the login screen, so use 403 (Forbidden) instead,
    # which is proper in any case according to https://stackoverflow.com/a/45405518/5961578
    def log_in_failure
      render json: {success: false, errors: {detail: {messages: [t('devise.sessions.invalid')]}}}, status: :forbidden
    end

    private

    def sign_in_and_redirect(resource_or_scope, resource = nil)
      scope = Devise::Mapping.find_scope!(resource_or_scope)
      resource ||= resource_or_scope
      sign_in(scope, resource) unless warden.user(scope) == resource
      render json: {success: true}, status: :created
    end
  end
end
