module OstConfig
  def self.admin_email
    ENV.fetch("ADMIN_EMAIL", "test@example.com")
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
    ENV.fetch("BASE_URI", "localhost:3000")
  end

  # All variations of "false", "f", "off", "0", "", and nil
  # will return false; all other values will return true.
  # For a complete list of values that will evaluate to false,
  # see ::ActiveModel::Type::Boolean::FALSE_VALUES
  def self.cast_to_boolean(value)
    return false if value.blank?

    ::ActiveModel::Type::Boolean.new.cast(value)
  end

  def self.cloudflare_analytics_token
    Rails.application.credentials.dig(:cloudflare, :analytics, :token)
  end

  def self.cloudflare_turnstile_secret_key
    Rails.application.credentials.dig(:cloudflare, :turnstile, :secret_key)
  end

  def self.cloudflare_turnstile_site_key
    Rails.application.credentials.dig(:cloudflare, :turnstile, :site_key)
  end

  def self.credentials_content_path
    if credentials_env?
      Rails.root.join("config/credentials/#{credentials_env}.yml.enc")
    else
      Rails.root.join("config/credentials.yml.enc")
    end
  end

  def self.credentials_env
    ENV.fetch("CREDENTIALS_ENV", nil)
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
    ENV.fetch("FULL_URI", "http://localhost:3000")
  end

  def self.app_name
    case credentials_env
    when "production"
      "OpenSplitTime"
    when "staging"
      "OST Staging"
    else
      "OST"
    end
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

  def self.scout_apm_app_name
    if credentials_env == "production"
      "OpenSplitTime"
    elsif credentials_env == "staging"
      "ost-staging"
    end
  end

  def self.scout_apm_key
    Rails.application.credentials.dig(:scout, :agent_key)
  end

  def self.scout_apm_logs_ingest_key
    Rails.application.credentials.dig(:scout, :logs_ingest_key)
  end

  def self.scout_apm_sample_rate
    ENV.fetch("SCOUT_APM_SAMPLE_RATE", nil)&.to_f || 1.0
  end

  def self.mailgun_api_key
    Rails.application.credentials.dig(:mailgun, :api_key)
  end

  def self.mailgun_domain
    Rails.application.credentials.dig(:mailgun, :domain)
  end

  def self.mailgun_webhook_signing_key
    Rails.application.credentials.dig(:mailgun, :webhook_signing_key)
  end

  def self.shortened_uri
    ENV.fetch("SHORTENED_URI", base_uri)
  end

  def self.docs_base_url
    ENV.fetch("DOCS_BASE_URL") do
      Rails.env.development? ? "http://localhost:4000" : "https://docs.opensplittime.org"
    end
  end
end
