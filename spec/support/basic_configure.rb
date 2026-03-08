RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  # better_cuprite is the default driver for system tests
  # use better_cuprite_visible for debugging
  config.before(:each, type: :system, js: true) do
    driven_by :better_cuprite
    # driven_by :better_cuprite_visible

    download_path = Rails.root.join("tmp/downloads")
    FileUtils.mkdir_p(download_path)
    
    # Configure Chrome downloads via CDP
    if page.driver.respond_to?(:browser) && page.driver.browser.respond_to?(:command)
      page.driver.browser.command("Browser.setDownloadBehavior", 
        behavior: "allow",
        downloadPath: download_path.to_s
      )
    end
  end

  config.filter_gems_from_backtrace("capybara", "cuprite", "ferrum")
end
