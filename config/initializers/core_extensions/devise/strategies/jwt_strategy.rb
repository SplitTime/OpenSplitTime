module Devise
  module Strategies
    class JwtStrategy < Base
      def valid?
        request.headers['Authorization'].present?
      end

      def authenticate!
        token = request.headers.fetch("Authorization", "").split(" ").last
        payload = JsonWebToken.decode(token)

        env['devise.skip_trackable'] = true
        user = User.find(payload["sub"])
        user.has_json_web_token = true
        success! user

      rescue JWT::ExpiredSignature
        fail! 'Auth token has expired'
      rescue JWT::DecodeError
        fail! 'Auth token is invalid'
      end
    end
  end
end