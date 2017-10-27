chrome_bin = ENV.fetch('GOOGLE_CHROME_SHIM', nil)

binary_options = chrome_bin ? {binary: chrome_bin} : {}
headless_options = {args: %w(headless disable-gpu)}

Capybara.register_driver :chrome do |app|
  chrome_options = {chromeOptions: binary_options}
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(chrome_options)
  # noinspection RubyArgCount
  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 desired_capabilities: capabilities)
end

Capybara.register_driver :headless_chrome do |app|
  chrome_options = {chromeOptions: binary_options.merge(headless_options)}
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(chrome_options)
  # noinspection RubyArgCount
  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 desired_capabilities: capabilities)
end
