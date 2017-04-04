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
    @permitted_params ||= params_class.strong_params(controller_class_name, params)
  end

  def params_class
    @params_class ||= "#{controller_class}Parameters".constantize
  end

  def controller_class
    controller_class_name.camelcase.constantize
  end

  def controller_class_name
    params[:controller].split('/').last.to_s.singularize
  end

  def user_not_authorized
    flash[:alert] = "Access denied."
    redirect_to (request.referrer || root_path)
  end

  def set_current_user
    User.current = current_user
  end

end
