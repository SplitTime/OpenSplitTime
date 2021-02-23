# frozen_string_literal: true

module OstConfig
  def self.google_recaptcha_enabled?
    google_recaptcha_secret_key.present? &&
    google_recaptcha_site_key.present?
  end

  def self.google_recaptcha_secret_key
    ENV["GOOGLE_RECAPTCHA_SECRET_KEY"]
  end

  def self.google_recaptcha_site_key
    ENV["GOOGLE_RECAPTCHA_SITE_KEY"]
  end
end
