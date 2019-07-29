class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :store_user_location!, if: :storable_location?
  before_action :set_current_user
  helper_method :prepared_params

  impersonates :user

  if Rails.env.development? | Rails.env.test?
    # https://github.com/RailsApps/rails-devise-pundit/issues/10
    include Pundit
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  end

  protected

  def after_sign_in_path_for(resource)
    stored_location_for(resource) ||
        devise_controller? ? root_path : request.referrer ||
        root_path
  end

  def after_sign_out_path_for(resource)
    stored_location_for(resource) || request.referrer || root_path
  end

  private

  # It's important that the location is NOT stored if:
  # - The request method is not GET (non idempotent)
  # - The request is handled by a Devise controller such as Devise::SessionsController as that could cause an
  #    infinite redirect loop.
  # - The request is an Ajax request as this can lead to very unexpected behaviour.
  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end

  def store_user_location!
    store_location_for(:user, request.fullpath)
  end

  def prepared_params
    @prepared_params ||= PreparedParams.new(params, params_class.permitted, params_class.permitted_query)
  end

  def permitted_params
    @permitted_params ||= params_class.strong_params(params)
  end

  def params_class
    @params_class ||= "#{controller_class}Parameters".constantize
  end

  def policy_class
    @policy_class ||= "#{controller_class}Policy".constantize
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

  def set_flash_message(response)
    if response.successful?
      flash[:success] = [flash[:success], response.message].compact.join("\n").presence
    else
      flash[:warning] = [flash[:warning], response.message_with_error_report].compact.join("\n").presence
    end
  end

  def jsonapi_error_object(record)
    {title: "#{record.class} could not be #{past_tense[action_name]}",
     detail: {attributes: record.attributes.compact.transform_keys { |key| key.camelize(:lower) },
              messages: record.errors.full_messages}}
  end

  def child_records_error_object(record, child_record_model)
    klass = record.class
    child_records = record.send(child_record_model)
    human_child_model_name = child_record_model.to_s.humanize(capitalize: false)
    {title: "#{klass} could not be #{past_tense[action_name]}",
     detail: {messages: ["A #{klass} can be deleted only if it has no associated #{human_child_model_name}. " +
                             "This #{klass} has #{child_records.size} associated #{human_child_model_name}, including " +
                             "#{child_records.first(20).map(&:to_s).join(', ')}"]}}
  end

  def redirect_numeric_to_friendly(resource, id_param)
    if request.request_method_symbol == :get && resource.friendly_id != id_param
      redirect_to request.params.merge(id: resource.friendly_id), status: 301
    end
  end

  # This should really be a helper method
  def past_tense
    result = {
        create: :created,
        update: :updated,
        destroy: :destroyed
    }.with_indifferent_access
    result.default = :saved
    result
  end
end
