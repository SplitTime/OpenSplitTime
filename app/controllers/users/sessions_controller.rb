# https://github.com/plataformatec/devise/wiki/How-To:-redirect-to-a-specific-page-on-successful-sign-in

module Users
  class SessionsController < Devise::SessionsController
    def new
      self.resource = resource_class.new(sign_in_params)
      store_location_for(resource, params[:redirect_to])
      super
    end
  end
end
