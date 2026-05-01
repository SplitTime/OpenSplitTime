require "aws-sdk-pinpointsmsvoicev2"

class PinpointSmsClientFactory
  # @return [Aws::PinpointSMSVoiceV2::Client]
  def self.client
    if ::OstConfig.aws_stub_responses?
      Aws::PinpointSMSVoiceV2::Client.new(stub_responses: true, region: ::OstConfig.aws_region)
    else
      Aws::PinpointSMSVoiceV2::Client.new(region: ::OstConfig.aws_region)
    end
  end
end
