# https://github.com/plataformatec/devise/wiki/How-To:-redirect-to-a-specific-page-on-successful-sign-in

module Users
  class SessionsController < Devise::SessionsController
    def create
      resource = warden.authenticate!(scope: resource_name, recall: "#{controller_path}#failure")
      sign_in_and_redirect(resource_name, resource)
    end

    def failure
      render json: {success: false, errors: ["Invalid email or password."]}
    end

    private

    def sign_in_and_redirect(resource_or_scope, resource = nil)
      scope = Devise::Mapping.find_scope!(resource_or_scope)
      resource ||= resource_or_scope
      sign_in(scope, resource) unless warden.user(scope) == resource
      render json: {success: true}
    end
  end
end
