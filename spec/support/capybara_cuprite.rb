# spec/support/capybara_cuprite.rb
require "capybara/rspec"
require "capybara/cuprite"

Capybara.default_max_wait_time = 5
Capybara.disable_animation = true if Capybara.respond_to?(:disable_animation)

# Find Chrome/Chromium binary (dynamic version-agnostic paths)
def find_chrome_binary
  return ENV["BROWSER_PATH"] if ENV["BROWSER_PATH"]&.present?
  
  # Homebrew Cask Chrome (version-agnostic)
  homebrew_chrome = Dir.glob("/opt/homebrew/Caskroom/google-chrome/*/Google Chrome.app/Contents/MacOS/Google Chrome").first
  return homebrew_chrome if homebrew_chrome&.present? && File.exist?(homebrew_chrome)
  
  # Standard macOS locations
  [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium"
  ].each do |path|
    return path if File.exist?(path)
  end
  
  # Fall back to PATH
  `which chromium`.strip.presence || 
  `which google-chrome-stable`.strip.presence ||
  `which google-chrome`.strip.presence
end

CHROME_BINARY = find_chrome_binary

Capybara.register_driver :better_cuprite do |app|
  options = {
    headless: ENV.fetch("HEADLESS", "true") == "true",
    window_size: [1500, 1200],
    browser_options: ENV["CI"] ? { "no-sandbox" => nil } : {},
    process_timeout: 30,
    timeout: 15,
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
    process_timeout: 30,
    timeout: 15,
    js_errors: true,
  }
  
  options[:browser_path] = CHROME_BINARY if File.exist?(CHROME_BINARY)
  
  Capybara::Cuprite::Driver.new(app, options)
end

Capybara.javascript_driver = :better_cuprite
