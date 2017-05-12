class ApiController < ApplicationController
  protect_from_forgery with: :null_session
  skip_before_action :verify_authenticity_token, if: :json_web_token_present?
  before_action :set_default_format
  before_action :authenticate_user!
  after_action :verify_authorized
  after_action :report_to_ga
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  # Returns only those resources that the user is authorized to edit.
  def index
    authorize controller_class
    render json: policy_class::Scope.new(current_user, controller_class).editable.order(prepared_params[:sort]),
           include: prepared_params[:include], fields: prepared_params[:fields]
  end

  def show
    authorize @resource
    render json: @resource, include: prepared_params[:include], fields: prepared_params[:fields]
  end

  def create
    @resource = controller_class.new(permitted_params)
    authorize @resource

    if @resource.save
      render json: @resource, status: :created
    else
      render json: {errors: [jsonapi_error_object(@resource)]}, status: :unprocessable_entity
    end
  end

  def update
    authorize @resource
    if @resource.update(permitted_params)
      render json: @resource
    else
      render json: {errors: [jsonapi_error_object(@resource)]}, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @resource
    if @resource.destroy
      render json: @resource
    else
      render json: {errors: [jsonapi_error_object(@resource)]}, status: :unprocessable_entity
    end
  end

  private

  def set_resource
    @resource = controller_class.friendly.find(params[:id])
  end

  def policy_class
    @policy_class ||= "#{controller_class}Policy".constantize
  end

  def permitted_params
    @permitted_params ||= prepared_params[:data]
  end

  def user_not_authorized
    render json: {errors: ['not authorized']}, status: :unauthorized
  end

  def set_default_format
    request.format = :json
  end

  def record_not_found
    render json: {errors: ['record not found']}, status: :not_found
  end

  def json_web_token_present?
    current_user.try(:has_json_web_token)
  end

  def report_to_ga
    if Rails.env.production?
      ga_params = {v: 1,
                   t: 'event',
                   tid: Rails.application.secrets.google_analytics_id,
                   cid: 555,
                   ec: controller_name,
                   ea: action_name,
                   el: params[:id],
                   uip: request.remote_ip,
                   ua: request.user_agent}
      ReportAnalyticsJob.perform_later(ga_params)
    end
  end
end
