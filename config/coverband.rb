# frozen_string_literal: true

Coverband.configure do |config|
  # default false. button at the top of the web interface which clears all data
  config.web_enable_clear = true

  # Experimental support for view layer tracking.
  # Does not track line-level usage, only indicates if an entire file
  # is used or not.
  config.track_views = true

  config.ignore += [
    'config/application.rb',
    'config/boot.rb',
    'config/puma.rb',
    'config/sitemap.rb',
    'bin/*',
    'config/environments/*',
    'lib/tasks/*',
  ]
end
