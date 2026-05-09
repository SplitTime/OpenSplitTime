require "rails_helper"

RSpec.describe SnsClientFactory do
  describe ".client" do
    context "when OstConfig.aws_stub_responses? is true" do
      before { allow(::OstConfig).to receive(:aws_stub_responses?).and_return(true) }

      it "stubs subscribe with the pre-configured subscription ARN" do
        response = described_class.client.subscribe(topic_arn: "arn:aws:sns:us-west-2:000000000000:any", protocol: "email", endpoint: "user@example.com")
        expect(response.subscription_arn).to eq(SnsClientFactory::STUB_SUBSCRIPTION_ARN)
      end

      it "stubs create_topic with the pre-configured topic ARN" do
        response = described_class.client.create_topic(name: "any")
        expect(response.topic_arn).to eq(SnsClientFactory::STUB_TOPIC_ARN)
      end

      it "stubs unsubscribe and delete_topic without raising" do
        client = described_class.client
        expect { client.unsubscribe(subscription_arn: "any") }.not_to raise_error
        expect { client.delete_topic(topic_arn: "any") }.not_to raise_error
      end
    end

    context "when OstConfig.aws_stub_responses? is false" do
      before { allow(::OstConfig).to receive(:aws_stub_responses?).and_return(false) }

      it "does NOT pre-configure the subscription ARN" do
        # The test environment globally stubs AWS, so a real call would still be
        # stubbed at the SDK level; what matters is that our factory hasn't
        # injected the pre-configured ARN.
        response = described_class.client.subscribe(topic_arn: "any", protocol: "email", endpoint: "user@example.com")
        expect(response.subscription_arn).not_to eq(SnsClientFactory::STUB_SUBSCRIPTION_ARN)
      end
    end
  end
end
