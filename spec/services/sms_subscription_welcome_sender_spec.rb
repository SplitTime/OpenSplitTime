require "rails_helper"

RSpec.describe SmsSubscriptionWelcomeSender do
  let(:user) { users(:admin_user) }
  let(:effort) { efforts(:hardrock_2015_tuan_jacobs) }
  let(:subscription) do
    Subscription.new(user: user, subscribable: effort, protocol: :sms, endpoint: "+13035551212").tap do |s|
      s.save(validate: false)
    end
  end
  let(:client) { instance_double(Aws::PinpointSMSVoiceV2::Client, send_text_message: nil) }

  before do
    allow(Aws::PinpointSMSVoiceV2::Client).to receive(:new).and_return(client)
    allow(::OstConfig).to receive_messages(aws_sms_origination_number: "+17626898865", aws_sms_welcome_enabled?: true)
    user.update!(phone: "+13035551212", phone_confirmed_at: Time.current, sms_carrier_opted_out_at: nil)
  end

  describe ".deliver" do
    context "when all preconditions are met" do
      it "calls send_text_message with the right destination, origination, and message body" do
        described_class.deliver(subscription)
        expect(client).to have_received(:send_text_message).with(
          destination_phone_number: user.phone,
          origination_identity: "+17626898865",
          message_body: a_string_matching(/You're now subscribed to live progress updates for #{effort.full_name} at #{effort.event_name}/),
          message_type: "TRANSACTIONAL",
        )
      end

      it "uses the participant's first name in the second sentence" do
        described_class.deliver(subscription)
        expect(client).to have_received(:send_text_message).with(
          a_hash_including(message_body: a_string_matching(/each time #{effort.first_name} passes an aid station/)),
        )
      end

      it "ends with a STOP reminder" do
        described_class.deliver(subscription)
        expect(client).to have_received(:send_text_message).with(
          a_hash_including(message_body: a_string_ending_with("Reply STOP to cancel.")),
        )
      end
    end

    context "when the welcome feature flag is disabled" do
      before { allow(::OstConfig).to receive(:aws_sms_welcome_enabled?).and_return(false) }

      it "does not call AWS" do
        described_class.deliver(subscription)
        expect(client).not_to have_received(:send_text_message)
      end
    end

    context "when no origination number is configured" do
      before { allow(::OstConfig).to receive(:aws_sms_origination_number).and_return(nil) }

      it "does not call AWS" do
        described_class.deliver(subscription)
        expect(client).not_to have_received(:send_text_message)
      end
    end

    context "when the subscribable is a Person (not Effort)" do
      let(:person) { people(:tuan_jacobs) }
      let(:subscription) do
        Subscription.new(user: user, subscribable: person, protocol: :sms, endpoint: "+13035551212").tap do |s|
          s.save(validate: false)
        end
      end

      it "does not call AWS (SMS welcomes are effort-only)" do
        described_class.deliver(subscription)
        expect(client).not_to have_received(:send_text_message)
      end
    end

    context "when the user has no phone" do
      before { user.update_column(:phone, nil) }

      it "does not call AWS" do
        described_class.deliver(subscription)
        expect(client).not_to have_received(:send_text_message)
      end
    end

    context "when the user is carrier-opted-out" do
      before { user.update_column(:sms_carrier_opted_out_at, 1.day.ago) }

      it "does not call AWS" do
        described_class.deliver(subscription)
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
        expect { described_class.deliver(subscription) }.not_to raise_error
        expect(Rails.error).to have_received(:report).with(
          an_instance_of(Aws::PinpointSMSVoiceV2::Errors::ValidationException),
          handled: true,
          context: hash_including(:subscription_id),
        )
      end
    end
  end
end
