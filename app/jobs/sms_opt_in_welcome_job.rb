class SmsOptInWelcomeJob < ApplicationJob
  queue_as :default

  def perform(user)
    SmsOptInWelcomeSender.deliver(user)
  end
end
