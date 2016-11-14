require 'rspec'
require 'time_difference'

RSpec.configure do |config|
  # Configure Timezone for proper tests
  ENV['TZ'] = 'UTC'
end