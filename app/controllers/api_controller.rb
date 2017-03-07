class ApiController < ApplicationController
  protect_from_forgery with: :null_session
  skip_before_action :verify_authenticity_token, if: :json_web_token_present?
  before_action :set_default_format
  before_action :authenticate_user!
  after_action :verify_authorized
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
end