# https://robots.thoughtbot.com/automatically-wait-for-ajax-with-capybara
# https://coderwall.com/p/aklybw/wait-for-ajax-with-capybara-2-0

module WaitForAjax
  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active') == 0
  end
end

RSpec.configure do |config|
  config.include WaitForAjax, type: :system
end
