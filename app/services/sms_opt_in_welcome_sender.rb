require "aws-sdk-pinpointsmsvoicev2"

class SmsOptInWelcomeSender
  def self.deliver(user)
    new(user).deliver
  end

  def initialize(user)
    @user = user
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
    Rails.error.report(e, handled: true, context: { user_id: user.id })
  end

  private

  attr_reader :user

  def deliverable?
    ::OstConfig.aws_sms_welcome_enabled? &&
      ::OstConfig.aws_sms_origination_number.present? &&
      user.phone.present? &&
      !user.sms_carrier_opted_out?
  end

  def message_body
    "OpenSplitTime: Thanks for opting in to SMS notifications. " \
      "You'll receive live progress updates when you subscribe to follow a participant. " \
      "Reply STOP to cancel, HELP for help. Msg & data rates may apply."
  end

  def client
    @client ||= Aws::PinpointSMSVoiceV2::Client.new(region: ::OstConfig.aws_region)
  end
end
