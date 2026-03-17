# frozen_string_literal: true

module Middleware
  # Rack middleware to reject requests with invalid UTF-8 encoding or null bytes.
  #
  # ## Problem
  #
  # Bots and scanners often send malformed URLs with:
  # 1. Invalid UTF-8 byte sequences (e.g., /%c0/, /%ff/)
  # 2. Null bytes (\x00) in query parameters (e.g., ?search=st%00%00)
  #
  # When Rails tries to parse these, it can raise ActionController::BadRequest
  # or ActionView::Template::Error ("string contains null byte"), which pollutes
  # error monitoring with junk traffic.
  #
  # ## Solution
  #
  # This middleware intercepts requests early in the Rack stack, before Rails routing.
  # If the request path or query string contains invalid UTF-8 or null bytes,
  # it returns 400 Bad Request immediately without hitting the application.
  class RejectInvalidUtf8
    def initialize(app)
      @app = app
    end

    def call(env)
      path = env["REQUEST_PATH"] || env["PATH_INFO"]
      query_string = env["QUERY_STRING"]

      return bad_request_response("path") unless valid_utf8_after_decode?(path)
      return bad_request_response("query") if query_string && contains_null_bytes?(query_string)

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

    def contains_null_bytes?(string)
      # Check for null bytes in the raw query string
      # URL-encoded null bytes appear as %00
      string.include?("\x00") || string.include?("%00")
    end

    def bad_request_response(location)
      message = case location
                when "path"
                  "Bad Request: Invalid UTF-8 in request path"
                when "query"
                  "Bad Request: Null bytes not allowed in query parameters"
                else
                  "Bad Request: Invalid request"
                end

      [
        400,
        { "Content-Type" => "text/plain" },
        [message]
      ]
    end
  end
end
