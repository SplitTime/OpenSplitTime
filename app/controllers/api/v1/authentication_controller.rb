class Api::V1::AuthenticationController < ApiController
  skip_before_action :authenticate_user!

  def create
    skip_authorization
    user = User.find_by(email: params[:user][:email])
    if user && user.valid_password?(params[:user][:password])
      render json: {token: JsonWebToken.encode(sub: user.id)}
    else
      render json: {errors: ['Invalid email or password']}, status: :bad_request
    end
  end
end