# https://robots.thoughtbot.com/automatically-wait-for-ajax-with-capybara
# https://coderwall.com/p/aklybw/wait-for-ajax-with-capybara-2-0

module WaitForCSS
  def wait_for_css
    sleep(0.5)
  end
end

RSpec.configure do |config|
  config.include WaitForCSS, type: :system
end
