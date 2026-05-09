require "rails_helper"

RSpec.describe SmsOptInWelcomeSender do
  let(:user) { users(:admin_user) }
  let(:client) { instance_double(Aws::PinpointSMSVoiceV2::Client, send_text_message: nil) }

  before do
    # Reference the factory so its `require "aws-sdk-pinpointsmsvoicev2"` runs
    # before the `instance_double(Aws::PinpointSMSVoiceV2::Client)` above resolves.
    allow(PinpointSmsClientFactory).to receive(:client).and_return(client)
    allow(::OstConfig).to receive(:aws_sms_origination_number).and_return("+14138458807")
    user.update!(phone: "+13035551212", phone_confirmed_at: Time.current, sms_carrier_opted_out_at: nil)
  end

  describe ".deliver" do
    context "when all preconditions are met" do
      it "calls send_text_message with the right destination, origination, and message body" do
        described_class.deliver(user)
        expect(client).to have_received(:send_text_message).with(
          destination_phone_number: user.phone,
          origination_identity: "+14138458807",
          message_body: a_string_starting_with("OpenSplitTime: Thanks for opting in to SMS notifications."),
          message_type: "TRANSACTIONAL",
        )
      end

      it "describes what the user has opted in to" do
        described_class.deliver(user)
        expect(client).to have_received(:send_text_message).with(
          a_hash_including(message_body: a_string_including("live progress updates when you subscribe to follow a participant")),
        )
      end

      it "ends with the standard CTIA disclosure (STOP, HELP, msg & data rates)" do
        described_class.deliver(user)
        expect(client).to have_received(:send_text_message).with(
          a_hash_including(message_body: a_string_ending_with("Reply STOP to cancel, HELP for help. Msg & data rates may apply.")),
        )
      end
    end

    context "when no origination number is configured" do
      before { allow(::OstConfig).to receive(:aws_sms_origination_number).and_return(nil) }

      it "does not call AWS" do
        described_class.deliver(user)
        expect(client).not_to have_received(:send_text_message)
      end
    end

    context "when the user has no phone" do
      before { user.update_column(:phone, nil) }

      it "does not call AWS" do
        described_class.deliver(user)
        expect(client).not_to have_received(:send_text_message)
      end
    end

    context "when the user is carrier-opted-out" do
      before { user.update_column(:sms_carrier_opted_out_at, 1.day.ago) }

      it "does not call AWS" do
        described_class.deliver(user)
        expect(client).not_to have_received(:send_text_message)
      end
    end

    context "when AWS raises a service error" do
      before do
        allow(client).to receive(:send_text_message).and_raise(
          Aws::PinpointSMSVoiceV2::Errors::ValidationException.new(nil, "boom"),
        )
        allow(Rails.error).to receive(:report)
      end

      it "swallows the error and reports it via Rails.error" do
        expect { described_class.deliver(user) }.not_to raise_error
        expect(Rails.error).to have_received(:report).with(
          an_instance_of(Aws::PinpointSMSVoiceV2::Errors::ValidationException),
          handled: true,
          context: hash_including(:user_id),
        )
      end
    end
  end
end
