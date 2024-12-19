Capybara.configure do |config|
  config.default_max_wait_time = 4
end

# chrome_headless is the default driver for system tests
Capybara.register_driver :chrome_headless do |app|
  download_path = Rails.root.join("tmp/downloads").to_s

  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless")
  options.add_argument("--disable-gpu")
  options.add_argument("--no-sandbox")
  options.add_argument("--window-size=1536,1152")
  options.add_argument("--disable-dev-shm-usage")
  options.add_preference(:download, directory_upgrade: true, prompt_for_download: false, default_directory: download_path)

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
  download_path = Rails.root.join("tmp/downloads").to_s

  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--disable-gpu")
  options.add_argument("--no-sandbox")
  options.add_argument("--window-size=1536,1152")
  options.add_argument("--disable-dev-shm-usage")
  options.add_preference(:download, directory_upgrade: true, prompt_for_download: false, default_directory: download_path)

  Capybara::Selenium::Driver.new app,
                                 browser: :chrome,
                                 clear_session_storage: true,
                                 clear_local_storage: true,
                                 options: options
end
