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

  def permitted_params
    @permitted_params ||= permitted_params_class.strong_params(params)
  end

  def permitted_params_class
    class_name = params[:controller].split('/').last
    formatted_class_name = class_name.to_s.singularize.camelcase
    @permitted_params_class ||= "#{formatted_class_name}Parameters".constantize
  end

  def user_not_authorized
    flash[:alert] = "Access denied."
    redirect_to (request.referrer || root_path)
  end

  def set_current_user
    User.current = current_user
  end

end
