class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :set_current_user

  if Rails.env.development? | Rails.env.test?
    # https://github.com/RailsApps/rails-devise-pundit/issues/10
    include Pundit
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  end

  private

  def user_not_authorized
    flash[:alert] = "Access denied."
    redirect_to (request.referrer || root_path)
  end

  def set_current_user
    User.current = current_user
  end

  def auth_user
    redirect_to new_user_registration_path unless @current_user.present?
  end

end
