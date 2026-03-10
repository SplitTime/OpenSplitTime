# frozen_string_literal: true

module Middleware
  # Rack middleware to reject requests with invalid UTF-8 encoding in the path.
  #
  # ## Problem
  #
  # Bots and scanners often send malformed URLs with invalid UTF-8 byte sequences
  # (e.g., /%c0/, /%ff/). When Rails tries to parse these, it raises
  # ActionController::BadRequest, which pollutes error monitoring with junk traffic.
  #
  # ## Solution
  #
  # This middleware intercepts requests early in the Rack stack, before Rails routing.
  # If the request path contains invalid UTF-8, it returns 400 Bad Request immediately
  # without hitting the application.
  #
  # ## Benefits
  #
  # - Prevents ActionController::BadRequest from bot traffic
  # - Reduces error monitoring noise (Scout APM, Sentry, etc.)
  # - Slightly more efficient (rejects before Rails routing)
  # - Logs invalid requests for security monitoring
  #
  class RejectInvalidUtf8
    def initialize(app)
      @app = app
    end

    def call(env)
      path = env["REQUEST_PATH"] || env["PATH_INFO"]

      # URL-decode and check if the path is valid UTF-8
      # Invalid UTF-8 bytes like %c0 will fail this check after decoding
      unless valid_utf8_after_decode?(path)
        Rails.logger.warn("Rejected invalid UTF-8 request: #{path.inspect} from #{env['REMOTE_ADDR']}")
        return bad_request_response
      end

      @app.call(env)
    end

    private

    def valid_utf8_after_decode?(string)
      # URL-decode the path first (e.g., %c0 -> actual byte)
      # Then check if the decoded string is valid UTF-8
      begin
        decoded = URI.decode_www_form_component(string)
        decoded.force_encoding("UTF-8").valid_encoding?
      rescue ArgumentError
        # URI.decode_www_form_component can raise ArgumentError for invalid sequences
        false
      end
    end

    def bad_request_response
      [
        400,
        { "Content-Type" => "text/plain" },
        ["Bad Request: Invalid UTF-8 in request path"]
      ]
    end
  end
end
