# frozen_string_literal: true

module Middleware
  # Rack middleware to quietly reject requests whose body or query string Rails
  # cannot parse — typically malformed multipart bodies or bad query parameters
  # sent by bots and scanners.
  #
  # ## Problem
  #
  # Requests with empty/malformed multipart bodies or invalid query parameters
  # bubble up as ActionController::BadRequest. The exception is raised during
  # param normalization before any controller logic runs, so there is no
  # user-actionable bug to address — but each occurrence reports to Scout and
  # obscures real errors.
  #
  # ## Solution
  #
  # Wrap the downstream app in a rescue that catches ActionController::BadRequest
  # ONLY when its cause is one of a small set of known Rack parser errors, and
  # returns a plain 400 without re-raising. Unknown BadRequest causes still
  # propagate so legitimate signal is not swallowed.
  class RejectMalformedRequest
    KNOWN_PARSE_ERROR_CLASS_NAMES = %w[
      Rack::Multipart::EmptyContentError
      Rack::QueryParser::InvalidParameterError
      Rack::QueryParser::ParameterTypeError
    ].freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    rescue ActionController::BadRequest => e
      raise unless known_parse_error?(e.cause)

      [
        400,
        { "Content-Type" => "text/plain" },
        ["Bad Request: malformed request parameters"],
      ]
    end

    private

    def known_parse_error?(cause)
      return false unless cause

      KNOWN_PARSE_ERROR_CLASS_NAMES.include?(cause.class.name)
    end
  end
end
