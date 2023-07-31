# frozen_string_literal: true

module WaitMethods
  def wait_for_css
    sleep(1.5)
  end

  def wait_for_spinner_to_stop
    expect(page).not_to have_css(".fa-spin")
  end

  def wait_for_fill_in
    sleep(0.1)
  end
end

RSpec.configure do |config|
  config.include WaitMethods, type: :system
end
