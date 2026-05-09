require "rails_helper"

RSpec.describe PinpointSmsClientFactory do
  describe ".client" do
    it "uses the configured aws_region" do
      allow(::OstConfig).to receive(:aws_stub_responses?).and_return(true)
      expect(described_class.client.config.region).to eq(::OstConfig.aws_region)
    end

    context "when OstConfig.aws_stub_responses? is true" do
      before { allow(::OstConfig).to receive(:aws_stub_responses?).and_return(true) }

      it "passes stub_responses: true to the SDK so calls return canned responses without network" do
        # Empirically this is hard to assert directly because the test env globally
        # forces stub_responses; use a recording double to check what we passed.
        passed_args = nil
        allow(Aws::PinpointSMSVoiceV2::Client).to receive(:new) do |args|
          passed_args = args
          instance_double(Aws::PinpointSMSVoiceV2::Client)
        end
        described_class.client
        expect(passed_args).to include(stub_responses: true)
      end
    end

    context "when OstConfig.aws_stub_responses? is false" do
      before { allow(::OstConfig).to receive(:aws_stub_responses?).and_return(false) }

      it "does not pass stub_responses to the SDK constructor" do
        passed_args = nil
        allow(Aws::PinpointSMSVoiceV2::Client).to receive(:new) do |args|
          passed_args = args
          instance_double(Aws::PinpointSMSVoiceV2::Client)
        end
        described_class.client
        expect(passed_args).not_to include(:stub_responses)
      end
    end
  end
end
