require_relative "boot"

require "rails/all"
require_relative "./initializers/01_ost_config"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module OpenSplitTime
  class Application < Rails::Application
    # Initialize configuration defaults for a specific Rails version.
    config.load_defaults 6.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.time_zone = "UTC"

    config.autoload_paths += %W[#{config.root}/lib]
    config.autoload_paths += Dir[File.join(Rails.root, "lib", "core_ext", "**/*.rb")].each { |l| require l }

    config.exceptions_app = routes

    config.action_mailer.delivery_job = "ActionMailer::MailDeliveryJob"
    config.active_storage.variant_processor = :mini_magick
    config.active_support.remove_deprecated_time_with_zone_name = true

    if ::OstConfig.credentials_env?
      Rails.application.config.credentials.content_path = ::OstConfig.credentials_content_path
    end
  end
end
