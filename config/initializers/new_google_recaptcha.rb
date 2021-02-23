# frozen_string_literal: true

NewGoogleRecaptcha.setup do |config|
  config.site_key = ::OstConfig.google_recaptcha_site_key
  config.secret_key = ::OstConfig.google_recaptcha_secret_key
  config.minimum_score = 0.5
end
