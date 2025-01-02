# https://docs.sentry.io/clients/ruby/config/
Sentry.init do |config|
  config.dsn = ::OstConfig.sentry_dsn
  config.enabled_environments = ["production"]

  # Set to 1.0 to send 100% of events
  config.sample_rate = 1.0
end
