require_relative "boot"

require "rails/all"
require_relative "./initializers/01_ost_config"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module OpenSplitTime
  class Application < Rails::Application
    # Initialize configuration defaults for a specific Rails version.
    config.load_defaults 7.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.exceptions_app = routes

    config.action_mailer.delivery_job = "ActionMailer::MailDeliveryJob"
    config.active_storage.variant_processor = :mini_magick

    if ::OstConfig.credentials_env?
      Rails.application.config.credentials.content_path = ::OstConfig.credentials_content_path
    end

    # Make encrypted attributes from Rails 7.0 compatible with Rails 7.1
    Rails.application.config.active_record.encryption.hash_digest_class = OpenSSL::Digest::SHA256
    Rails.application.config.active_record.encryption.support_sha1_for_non_deterministic_encryption = true

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "UTC"
    # config.eager_load_paths << Rails.root.join("extras")

    Dir[Rails.root.join("lib/core_ext/**/*.rb")].each { |file| require file }
  end
end
