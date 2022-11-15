# frozen_string_literal: true

module OstConfig
  def self.admin_email
    ENV["ADMIN_EMAIL"] || "test@example.com"
  end

  def self.aws_access_key_id
    Rails.application.credentials.dig(:aws, :access_key_id)
  end

  def self.aws_region
    "us-west-2"
  end

  def self.aws_s3_bucket
    Rails.application.credentials.dig(:aws, :s3_bucket)
  end

  def self.aws_s3_bucket_public
    Rails.application.credentials.dig(:aws, :s3_bucket_public)
  end

  def self.aws_secret_access_key
    Rails.application.credentials.dig(:aws, :secret_access_key)
  end

  def self.base_uri
    ENV["BASE_URI"] || "localhost:3000"
  end

  # All variations of "false", "f", "off", "0", "", and nil
  # will return false; all other values will return true.
  # For a complete list of values that will evaluate to false,
  # see ::ActiveModel::Type::Boolean::FALSE_VALUES
  def self.cast_to_boolean(value)
    return false unless value.present?

    ::ActiveModel::Type::Boolean.new.cast(value)
  end

  def self.credentials_content_path
    if credentials_env?
      Rails.root.join("config/credentials/#{credentials_env}.yml.enc")
    else
      Rails.root.join("config/credentials.yml.enc")
    end
  end

  def self.credentials_env
    ENV["CREDENTIALS_ENV"]
  end

  def self.credentials_env?
    credentials_env.present?
  end

  def self.facebook_oauth_key
    Rails.application.credentials.dig(:facebook, :oauth, :key)
  end

  def self.facebook_oauth_secret
    Rails.application.credentials.dig(:facebook, :oauth, :secret)
  end

  def self.full_uri
    ENV["FULL_URI"] || "http://localhost:3000"
  end

  def self.google_analytics_4_measurement_id
    Rails.application.credentials.dig(:google, :analytics_4, :measurement_id)
  end

  def self.google_analytics_4_property_id
    Rails.application.credentials.dig(:google, :analytics_4, :property_id)
  end

  def self.google_maps_api_key
    Rails.application.credentials.dig(:google, :maps, :api_key)
  end

  def self.google_oauth_client_id
    Rails.application.credentials.dig(:google, :oauth, :client_id)
  end

  def self.google_oauth_client_secret
    Rails.application.credentials.dig(:google, :oauth, :client_secret)
  end

  def self.jwt_duration
    3.days
  end

  def self.scout_apm_sample_rate
    ENV["SCOUT_APM_SAMPLE_RATE"]&.to_f || 1.0
  end

  def self.sendgrid_api_key
    Rails.application.credentials.dig(:sendgrid, :api_key)
  end

  def self.sentry_dsn
    Rails.application.credentials.dig(:sentry, :dsn)
  end

  def self.shortened_uri
    ENV["SHORTENED_URI"] || base_uri
  end

  def self.timestamp_bot_detection?
    cast_to_boolean ENV["TIMESTAMP_BOT_DETECTION"]
  end
end
