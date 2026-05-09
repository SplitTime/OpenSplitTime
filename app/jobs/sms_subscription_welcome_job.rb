class SmsSubscriptionWelcomeJob < ApplicationJob
  queue_as :default

  def perform(subscription)
    SmsSubscriptionWelcomeSender.deliver(subscription)
  end
end
