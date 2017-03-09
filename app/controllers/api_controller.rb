class ApiController < ApplicationController
  protect_from_forgery with: :null_session
  skip_before_action :verify_authenticity_token, if: :json_web_token_present?
  before_action :set_default_format
  before_action :authenticate_user!
  before_action :underscore_include_param
  after_action :verify_authorized
  after_action :report_to_ga
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def user_not_authorized
    render json: {message: 'not authorized'}, status: :unauthorized
  end

  def set_default_format
    request.format = :json
  end

  def record_not_found
    render json: {message: 'record not found'}, status: :not_found
  end

  def json_web_token_present?
    current_user.try(:has_json_web_token)
  end

  def underscore_include_param
    params[:include] = (params[:include] || '').underscore
  end

  def report_to_ga
    if Rails.env.production?
      ga_params = {v: 1,
                   t: 'event',
                   tid: Rails.application.secrets.google_analytics_id,
                   cid: 555,
                   ec: controller_name,
                   ea: action_name,
                   el: params[:id]}
      ReportAnalyticsJob.perform_later(ga_params)
    end
  end
end