# spec/support/capybara_cuprite.rb
require "capybara/rspec"
require "capybara/cuprite"

Capybara.default_max_wait_time = 5
Capybara.disable_animation = true if Capybara.respond_to?(:disable_animation)

Capybara.register_driver :better_cuprite do |app|
  Capybara::Cuprite::Driver.new(
    app,
    headless: ENV.fetch("HEADLESS", "true") == "true",
    window_size: [1200, 800],
    browser_options: {},
    timeout: 10,
    js_errors: true
  )
end

Capybara.register_driver :better_cuprite_visible do |app|
  Capybara::Cuprite::Driver.new(
    app,
    headless: false,
    window_size: [1200, 800],
    browser_options: {},
    timeout: 10,
    js_errors: true
  )
end

Capybara.javascript_driver = :better_cuprite
Capybara.filter_gems_from_backtrace("capybara", "cuprite", "ferrum")
