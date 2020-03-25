# frozen_string_literal: true

class ApiController < ::ApplicationController
  include Rails::Pagination
  protect_from_forgery with: :null_session
  skip_before_action :verify_authenticity_token, if: :json_web_token_present?
  before_action :authenticate_user!
  after_action :verify_authorized
  after_action :report_to_ga
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found_json

  private

  def permitted_params
    @permitted_params ||= prepared_params[:data]
  end

  def user_not_authorized
    render json: {errors: ['not authorized']}, status: :unauthorized
  end

  def live_entry_unavailable(resource)
    {reportText: "Live entry for #{resource.name} is currently unavailable. " +
        'Please enable live entry access through the admin/settings page.'}
  end

  def json_web_token_present?
    !!current_user&.has_json_web_token
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
