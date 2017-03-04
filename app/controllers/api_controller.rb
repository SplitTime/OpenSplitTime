class ApiController < ApplicationController
  protect_from_forgery with: :null_session
  before_action :set_default_format
  before_action :authenticate_user!
  after_action :verify_authorized

  private

  def user_not_authorized
    puts "Content type is #{request.content_type}" # For debugging purposes
    render json: {message: 'not authorized'}, status: :unauthorized
  end

  def set_default_format
    request.format = :json
  end
end
