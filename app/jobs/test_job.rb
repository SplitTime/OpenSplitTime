class TestJob < ActiveJob::Base

  queue_as :default

  def perform(string)
    (0...string.length).each do |c|
      puts string[c]
      sleep 2
    end
  end

end