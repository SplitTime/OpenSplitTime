# https://github.com/plataformatec/devise/wiki/How-To:-redirect-to-a-specific-page-on-successful-sign-in

module Users
  class SessionsController < Devise::SessionsController
    def new
      self.resource = resource_class.new(sign_in_params)
      store_location_for(resource, params[:redirect_to])
      super
    end

    def create
      resource = User.find_for_database_authentication(email: params[:user][:email])

      respond_to do |format|
        format.json do
          if resource&.valid_password?(params[:user][:password])
            sign_in :user, resource
            render body: nil
          else
            set_flash_message(:alert, :invalid)
            render json: flash[:alert], status: 401
          end
        end
        format.html { super }
      end
    end
  end
end
