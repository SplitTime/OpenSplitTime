require "aws-sdk-sns"

class SnsClientFactory
  STUB_TOPIC_ARN = "arn:aws:sns:us-west-2:000000000000:dev-stub-topic".freeze
  STUB_SUBSCRIPTION_ARN = "arn:aws:sns:us-west-2:000000000000:dev-stub-topic:dev-stub-subscription".freeze

  # @return [Aws::SNS::Client]
  def self.client(**overrides)
    if ::OstConfig.aws_stub_responses?
      Aws::SNS::Client.new(stub_responses: true, **overrides).tap do |stubbed|
        stubbed.stub_responses(:create_topic, topic_arn: STUB_TOPIC_ARN)
        stubbed.stub_responses(:subscribe, subscription_arn: STUB_SUBSCRIPTION_ARN)
        stubbed.stub_responses(:unsubscribe, {})
        stubbed.stub_responses(:delete_topic, {})
      end
    else
      Aws::SNS::Client.new(**overrides)
    end
  end
end
