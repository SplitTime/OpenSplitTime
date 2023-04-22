# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  # chrome_headless is the default driver for system tests
  # use chrome_visible for debugging
  config.before(:each, type: :system, js: true) do
    driven_by :chrome_headless
  end
end
