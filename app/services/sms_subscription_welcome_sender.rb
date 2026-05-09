class SmsSubscriptionWelcomeSender
  def self.deliver(subscription)
    new(subscription).deliver
  end

  def initialize(subscription)
    @subscription = subscription
  end

  def deliver
    return unless deliverable?

    client.send_text_message(
      destination_phone_number: user.phone,
      origination_identity: ::OstConfig.aws_sms_origination_number,
      message_body: message_body,
      message_type: "TRANSACTIONAL",
    )
  rescue Aws::PinpointSMSVoiceV2::Errors::ServiceError => e
    Rails.error.report(e, handled: true, context: { subscription_id: subscription.id })
  end

  private

  attr_reader :subscription

  def deliverable?
    ::OstConfig.aws_sms_origination_number.present? &&
      subscription.subscribable.is_a?(Effort) &&
      user.phone.present? &&
      !user.sms_carrier_opted_out?
  end

  def user
    subscription.user
  end

  def effort
    subscription.subscribable
  end

  def message_body
    "OpenSplitTime: You're now subscribed to live progress updates for #{effort.full_name} " \
      "at #{effort.event_name}. You'll receive an SMS each time #{effort.first_name} " \
      "passes an aid station. Message frequency varies. Reply STOP to cancel."
  end

  def client
    @client ||= PinpointSmsClientFactory.client
  end
end
