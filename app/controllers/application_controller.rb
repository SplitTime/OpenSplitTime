class ApplicationController < ActionController::Base
  include Pundit
  include ::Turbo::Redirection

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :set_current_user
  before_action :set_paper_trail_whodunnit
  before_action :set_sentry_context
  before_action :sample_requests_for_scout_apm
  after_action :store_user_location!, if: :storable_location?
  helper_method :prepared_params

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActionController::UnknownFormat, with: :not_acceptable_head

  impersonates :user

  def process_action(*args)
    super
  rescue ActionDispatch::Http::MimeNegotiation::InvalidType => exception
    head :not_acceptable
  end

  protected

  def after_sign_in_path_for(resource)
    request.env['omniauth.origin'] ||
      stored_location_for(resource) ||
      (devise_controller? ? root_path : request.referrer) ||
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
    @prepared_params ||= PreparedParams.new(params, params_class&.permitted, params_class&.permitted_query)
  end

  def permitted_params
    @permitted_params ||= params_class.strong_params(controller_class_name, params)
  end

  def params_class
    @params_class ||= "#{controller_class}Parameters".safe_constantize
  end

  def policy_class
    @policy_class ||= "#{controller_class}Policy".safe_constantize
  end

  def controller_class
    controller_class_name.camelcase.safe_constantize
  end

  def controller_class_name
    params[:controller].split('/').last.to_s.singularize
  end

  def internal_server_error_json
    render json: {errors: ['internal server error']}, status: :internal_server_error
  end

  def not_acceptable_head
    head :not_acceptable
  end

  def record_not_found_json
    render json: {errors: ['record not found']}, status: :not_found
  end

  def unprocessable_entity_json
    render json: {errors: ['unprocessable entity']}, status: :unprocessable_entity
  end

  def user_not_authorized
    flash[:alert] = 'Access denied.'
    redirect_to(request.referrer || root_path)
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

  def set_sentry_context
    Sentry.set_user(id: current_user&.id)
    Sentry.set_extras(params: params.to_unsafe_h, url: request.url)
  end

  def sample_requests_for_scout_apm
    ::ScoutApm::Transaction.ignore! if rand > ::OstConfig.scout_apm_sample_rate
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
