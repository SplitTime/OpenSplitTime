# frozen_string_literal: true

module Api
  module V1
    class AuthenticationController < ::Api::V1::BaseController
      skip_before_action :authenticate_user!

      def create
        skip_authorization
        user = User.find_by(email: params[:user][:email])
        if user && user.valid_password?(params[:user][:password])
          if durable_token_requested? && durable_code_invalid?
            render json: {errors: ['Invalid durable code']}, status: :bad_request
          else
            render json: {token: JsonWebToken.encode({sub: user.id}, duration: token_duration),
                          expiration: Time.current + token_duration}
          end
        else
          render json: {errors: ['Invalid email or password']}, status: :bad_request
        end
      rescue
        render json: {errors: ['Invalid request']}, status: :bad_request
      end

      private

      def durable_token_requested?
        params[:durable].present?
      end

      def durable_code_invalid?
        ENV['DURABLE_JWT_CODE'] && params[:durable] != ENV['DURABLE_JWT_CODE']
      end

      def token_duration
        durable_token_requested? ? Rails.application.secrets.jwt_duration_long : Rails.application.secrets.jwt_duration
      end
    end
  end
end
