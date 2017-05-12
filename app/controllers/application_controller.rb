class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :set_current_user
  helper_method :prepared_params

  if Rails.env.development? | Rails.env.test?
    # https://github.com/RailsApps/rails-devise-pundit/issues/10
    include Pundit
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  end

  private

  def prepared_params
    @prepared_params ||= PreparedParams.new(params, params_class.permitted, params_class.permitted_query)
  end

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
    flash[:alert] = 'Access denied.'
    redirect_to (request.referrer || root_path)
  end

  def set_current_user
    User.current = current_user
  end

  def jsonapi_error_object(record)
    {title: "#{record.class} could not be #{past_tense[action_name]}",
     detail: {attributes: record.attributes.compact, messages: record.errors.full_messages}}
  end

  def past_tense
    {create: :created,
     update: :updated,
     destroy: :destroyed}.with_indifferent_access
  end
end
