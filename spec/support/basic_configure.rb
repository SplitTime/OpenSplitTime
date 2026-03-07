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
  end

  config.filter_gems_from_backtrace("capybara", "cuprite", "ferrum")
end
