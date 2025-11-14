# config/initializers/sprockets_cache.rb
if Rails.env.development?
  Rails.application.config.assets.configure do |env|
    # Disable filesystem cache to avoid Windows rename permission issues
    env.cache = ActiveSupport::Cache::NullStore.new
  end
end
