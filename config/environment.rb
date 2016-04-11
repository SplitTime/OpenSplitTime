# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

Time::DATE_FORMATS[:submitted] = "%b %d %Y"

Time::DATE_FORMATS[:time_short] = ""
Time::DATE_FORMATS[:time_long] = ""