# config/initializers/pundit.rb
# Extends the ApplicationController to add Pundit for authorization.
# Modify this file to change the behavior of a 'not authorized' error.
# Be sure to restart your server when you modify this file.
module PunditHelper
  extend ActiveSupport::Concern

  included do
    include Pundit
    # https://github.com/elabs/pundit#ensuring-policies-are-used
    # after_filter :verify_authorized,  except: :index  # TODO: fix these verifications
    # after_filter :verify_policy_scoped, only: :index

    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  end

  private

  def user_not_authorized
    flash[:alert] = "Access denied."
    redirect_to (request.referrer || root_path)
  end

end

ApplicationController.send :include, PunditHelper unless Rails.env.development?
