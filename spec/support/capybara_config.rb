Capybara.configure do |config|
  config.default_max_wait_time = 4
end

# chrome_headless is the default driver for system tests
Capybara.register_driver :chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new(
    args: %w[headless disable-gpu no-sandbox window-size=1024,768],
    )
  Capybara::Selenium::Driver.new app,
                                 browser: :chrome,
                                 clear_session_storage: true,
                                 clear_local_storage: true,
                                 options: options
end

# chrome_visible can be used for debugging by changing the argument
# passed to `driven_by` in spec/support/basic_configure.rb from
# :chrome_headless to :chrome_visible
Capybara.register_driver :chrome_visible do |app|
  options = Selenium::WebDriver::Chrome::Options.new(
    args: %w[disable-gpu no-sandbox window-size=1024,768],
  )
  Capybara::Selenium::Driver.new app,
                                 browser: :chrome,
                                 clear_session_storage: true,
                                 clear_local_storage: true,
                                 options: options
end
