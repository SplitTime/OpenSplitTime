# https://github.com/plataformatec/devise/wiki/How-To:-redirect-to-a-specific-page-on-successful-sign-in

module Users
  class PasswordsController < Devise::PasswordsController

    protected

    def after_resetting_password_path_for(resource)
      signed_in_root_path(resource)
    end
  end
end
