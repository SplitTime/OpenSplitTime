# frozen_string_literal: true

class JsonWebToken
  def self.encode(payload, duration: nil)
    duration ||= OstConfig.jwt_duration

    payload = payload.dup
    payload["exp"] = (Time.current + duration).to_i

    JWT.encode(payload, Rails.application.secret_key_base)
  end

  def self.decode(token)
    JWT.decode(token, Rails.application.secret_key_base).first
  end
end
