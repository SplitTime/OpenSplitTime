class Api::V1::AuthenticationController < ApiController
  skip_before_action :authenticate_user!

  def create
    skip_authorization
    user = User.find_by(email: params[:user][:email])
    if user && user.valid_password?(params[:user][:password])
      if params[:code] == ENV['DURABLE_JWT_CODE']
        p "Durable JWT generated for #{user.email}, #{user.id}"
        render json: {token: JsonWebToken.encode({sub: user.id}, duration: Rails.application.secrets.jwt_duration_long)}
      else
        p "JWT generated for #{user.email}, #{user.id}"
        render json: {token: JsonWebToken.encode(sub: user.id)}
      end
    else
      render json: {errors: ['Invalid email or password']}, status: :bad_request
    end
  rescue
    render json: {errors: ['Invalid request']}, status: :bad_request
  end
end
