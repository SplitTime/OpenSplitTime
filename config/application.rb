require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module OpenSplitTime
  class Application < Rails::Application
    # Initialize configuration defaults for a specific Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.time_zone = "UTC"

    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir[File.join(Rails.root, "lib", "core_ext", "**/*.rb")].each { |l| require l }

    config.exceptions_app = self.routes

    config.action_mailer.delivery_job = "ActionMailer::MailDeliveryJob"
  end
end
