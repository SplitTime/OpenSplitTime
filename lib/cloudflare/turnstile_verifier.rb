# frozen_string_literal: true

module Cloudflare
  class TurnstileVerifier
    TURNSTILE_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"

    # @param [String] token
    # @return [Boolean]
    def self.token_valid?(token)
      http_client = ::RestClient
      params = {
        response: token,
        secret: ::OstConfig.cloudflare_turnstile_secret_key,
      }

      response = http_client.post(TURNSTILE_URL, params)
      parsed_response = JSON.parse(response.body)
      parsed_response["success"] == true
    end
  end
end
