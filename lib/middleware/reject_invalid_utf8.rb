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
  class RejectInvalidUtf8
    def initialize(app)
      @app = app
    end

    def call(env)
      path = env["REQUEST_PATH"] || env["PATH_INFO"]
      return bad_request_response unless valid_utf8_after_decode?(path)

      @app.call(env)
    end

    private

    def valid_utf8_after_decode?(string)
      decoded = URI.decode_www_form_component(string)
      decoded.force_encoding("UTF-8").valid_encoding?
    rescue ArgumentError
      # URI.decode_www_form_component can raise ArgumentError for invalid sequences
      false
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
