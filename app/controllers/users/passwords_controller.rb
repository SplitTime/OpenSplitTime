# https://github.com/plataformatec/devise/wiki/How-To:-redirect-to-a-specific-page-on-successful-sign-in

module Users
  class PasswordsController < Devise::PasswordsController
    protected

    def after_resetting_password_path_for(resource)
      signed_in_root_path(resource)
    end

    def after_sending_reset_password_instructions_path_for(_resource_name)
      root_path
    end
  end
end
