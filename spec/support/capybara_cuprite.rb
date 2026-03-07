# spec/support/capybara_cuprite.rb
require "capybara/rspec"
require "capybara/cuprite"

Capybara.default_max_wait_time = 5
Capybara.disable_animation = true if Capybara.respond_to?(:disable_animation)

# Find Chrome/Chromium binary
CHROME_BINARY = ENV["BROWSER_PATH"] || 
                `which chromium`.strip.presence || 
                `which google-chrome-stable`.strip.presence ||
                `which google-chrome`.strip.presence ||
                "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

Capybara.register_driver :better_cuprite do |app|
  options = {
    headless: ENV.fetch("HEADLESS", "true") == "true",
    window_size: [1500, 1200],
    browser_options: ENV["CI"] ? { "no-sandbox" => nil } : {},
    process_timeout: 15,
    timeout: 10,
    js_errors: true,
  }
  
  options[:browser_path] = CHROME_BINARY if File.exist?(CHROME_BINARY)
  
  Capybara::Cuprite::Driver.new(app, options)
end

Capybara.register_driver :better_cuprite_visible do |app|
  options = {
    headless: false,
    window_size: [1500, 1200],
    browser_options: {},
    process_timeout: 15,
    timeout: 10,
    js_errors: true,
  }
  
  options[:browser_path] = CHROME_BINARY if File.exist?(CHROME_BINARY)
  
  Capybara::Cuprite::Driver.new(app, options)
end

Capybara.javascript_driver = :better_cuprite
