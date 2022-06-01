# frozen_string_literal: true

module Api
  module V1
    class AuthenticationController < ::Api::V1::BaseController
      skip_before_action :authenticate_user!

      def create
        skip_authorization
        user = User.find_by(email: params[:user][:email])
        if user && user.valid_password?(params[:user][:password])
          render json: {token: JsonWebToken.encode({sub: user.id}, duration: token_duration),
                        expiration: Time.current + token_duration}
        else
          render json: {errors: ["Invalid email or password"]}, status: :bad_request
        end
      rescue StandardError
        render json: {errors: ["Invalid request"]}, status: :bad_request
      end

      private

      def token_duration
        OstConfig.jwt_duration
      end
    end
  end
end
