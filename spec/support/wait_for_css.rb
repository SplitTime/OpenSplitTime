module WaitMethods
  def wait_for_css
    sleep(1.5)
  end

  def wait_for_fill_in
    sleep(0.1)
  end
end

RSpec.configure do |config|
  config.include WaitMethods, type: :system
end
