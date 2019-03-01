Rails.application.configure do
  # Verifies that versions and hashed value of the package contents in the project's package.json
  config.webpacker.check_yarn_integrity = true

  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  config.action_mailer.delivery_method = :sendmail
  config.action_mailer.smtp_settings = {address: 'localhost', port: 25, domain: 'whatever.com'}
  config.action_mailer.default_url_options = {host: ENV['BASE_URI']}

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Do care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  config.active_job.queue_adapter = :sidekiq

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
  config.paperclip_defaults = {
      storage: :s3,
      preserve_files: true,
      s3_credentials: {
          bucket: ENV['S3_BUCKET'],
          access_key_id: ENV['AWS_ACCESS_KEY_ID'],
          secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
          s3_region: ENV['AWS_REGION'],
          s3_host_name: "s3-#{ENV['AWS_REGION']}.amazonaws.com",
      }
  }

  if ENV['MEMCACHEDCLOUD_SERVERS']
    config.cache_store = :dalli_store, ENV['MEMCACHEDCLOUD_SERVERS'].split(','), { namespace: Rails.env, expires_in: 4.hours, compress: true, username: ENV['MEMCACHEDCLOUD_USERNAME'], password: ENV['MEMCACHEDCLOUD_PASSWORD'] }
  end

  config.assets.quiet = true

  # ActiveStorage
  config.active_storage.service = :amazon
end
