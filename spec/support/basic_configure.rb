RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  # chrome_headless is the default driver for system tests
  # use chrome_visible for debugging
  config.before(:each, type: :system, js: true) do
    driven_by :better_cuprite
    # driven_by :better_cuprite_visible
  end

  config.filter_gems_from_backtrace("capybara", "cuprite", "ferrum")
end
