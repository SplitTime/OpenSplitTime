# frozen_string_literal: true

module Api
  module V1
    class AuthenticationController < ::Api::V1::BaseController
      skip_before_action :authenticate_user!
      around_action :log_everything

      def create
        skip_authorization
        user = User.find_by(email: params[:user][:email])
        if user && user.valid_password?(params[:user][:password])
          render json: {
            token: JsonWebToken.encode({ sub: user.id }, duration: token_duration),
            expiration: Time.current + token_duration
          }
        else
          render json: { errors: ["Invalid email or password"] }, status: :bad_request
        end
      rescue StandardError
        render json: { errors: ["Invalid request"] }, status: :bad_request
      end

      private

      def token_duration
        OstConfig.jwt_duration
      end

      def log_everything
        log_headers
        yield
      ensure
        log_response
      end

      def log_headers
        http_envs = {}.tap do |envs|
          request.headers.each do |key, value|
            envs[key] = value if key.downcase.starts_with?('http')
          end
        end

        logger.info "Received #{request.method.inspect} to #{request.url.inspect} from #{request.remote_ip.inspect}. Processing with headers #{http_envs.inspect} and params #{params.inspect}"
      end

      def log_response
        logger.info "Responding with #{response.status.inspect} => #{response.body.inspect}"
      end
    end
  end
end
