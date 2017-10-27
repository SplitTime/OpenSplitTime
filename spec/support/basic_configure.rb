# Noel Rappin at https://medium.com/table-xi/a-quick-guide-to-rails-system-tests-in-rspec-b6e9e8a8b5f6

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    # For compatibility with Heroku CI, driven_by must be set to a Capybara registered driver
    # that sets chromeOptions: :binary to the path of the chrome assets in the Heroku CI environment
    driven_by :headless_chrome
  end
end
