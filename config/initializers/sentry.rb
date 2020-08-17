# frozen_string_literal: true

# https://docs.sentry.io/clients/ruby/config/
Raven.configure do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
  config.environments = ["production"]

  # Set to 1.0 to send 100% of events
  config.sample_rate = 1.0

  config.async = lambda { |event| SentryJob.perform_later(event) }
end
