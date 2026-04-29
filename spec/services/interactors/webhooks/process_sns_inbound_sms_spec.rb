require "rails_helper"

RSpec.describe Interactors::Webhooks::ProcessSnsInboundSms do
  let(:phone) { "+13038806481" }
  let(:destination) { "+17626898865" }
  let(:message_body) { "STOP" }
  let(:received_at_str) { "2026-04-29T10:00:00Z" }
  let(:sns_message_id) { "11111111-2222-3333-4444-555555555555" }
  let(:inbound_message_id) { "psv2-inbound-id-1" }

  let(:inbound_payload) do
    {
      "originationNumber" => phone,
      "destinationNumber" => destination,
      "messageBody" => message_body,
      "inboundMessageId" => inbound_message_id,
    }
  end

  let(:sns_message) do
    {
      "Type" => "Notification",
      "MessageId" => sns_message_id,
      "Timestamp" => received_at_str,
      "Message" => inbound_payload.to_json,
    }
  end

  describe ".call" do
    subject(:result) { described_class.call(sns_message: sns_message) }

    context "with a STOP keyword from a phone matching one user" do
      let!(:user) { create(:user, phone: phone, phone_confirmed_at: Time.current) }

      it "is successful" do
        expect(result.errors).to be_empty
      end

      it "creates an Analytics::SmsInboundMessage row with the correct attributes" do
        expect { result }.to change(Analytics::SmsInboundMessage, :count).by(1)
        record = Analytics::SmsInboundMessage.last
        expect(record.origination_number).to eq(phone)
        expect(record.destination_number).to eq(destination)
        expect(record.message_body).to eq("STOP")
        expect(record.keyword).to eq("STOP")
        expect(record.sns_message_id).to eq(sns_message_id)
        expect(record.inbound_message_id).to eq(inbound_message_id)
      end

      it "sets sms_carrier_opted_out_at on the matching user" do
        result
        expect(user.reload.sms_carrier_opted_out_at).to be_within(1.second).of(Time.zone.parse(received_at_str))
      end
    end

    context "with a START keyword from a phone matching one carrier-opted-out user" do
      let!(:user) { create(:user, phone: phone, phone_confirmed_at: Time.current, sms_carrier_opted_out_at: 2.days.ago) }
      let(:message_body) { "START" }

      it "clears sms_carrier_opted_out_at on the matching user" do
        result
        expect(user.reload.sms_carrier_opted_out_at).to be_nil
      end

      it "records keyword as START" do
        result
        expect(Analytics::SmsInboundMessage.last.keyword).to eq("START")
      end
    end

    context "with a HELP keyword" do
      let!(:user) { create(:user, phone: phone, phone_confirmed_at: Time.current) }
      let(:message_body) { "HELP" }

      it "records the message but does not change user state" do
        expect { result }.to change(Analytics::SmsInboundMessage, :count).by(1)
        expect(Analytics::SmsInboundMessage.last.keyword).to eq("HELP")
        expect(user.reload.sms_carrier_opted_out_at).to be_nil
      end
    end

    context "with a non-keyword body like 'hello'" do
      let!(:user) { create(:user, phone: phone, phone_confirmed_at: Time.current) }
      let(:message_body) { "hello" }

      it "records the message with keyword nil and does not change user state" do
        expect { result }.to change(Analytics::SmsInboundMessage, :count).by(1)
        expect(Analytics::SmsInboundMessage.last.keyword).to be_nil
        expect(user.reload.sms_carrier_opted_out_at).to be_nil
      end
    end

    context "with leading whitespace and lowercase keyword" do
      let!(:user) { create(:user, phone: phone, phone_confirmed_at: Time.current) }
      let(:message_body) { "  stop please " }

      it "still parses STOP as the keyword" do
        result
        expect(Analytics::SmsInboundMessage.last.keyword).to eq("STOP")
        expect(user.reload.sms_carrier_opted_out_at).to be_present
      end
    end

    context "when the same sns_message_id is processed twice" do
      let!(:user) { create(:user, phone: phone, phone_confirmed_at: Time.current) }

      it "does not create a duplicate row" do
        described_class.call(sns_message: sns_message)
        expect { described_class.call(sns_message: sns_message) }.not_to change(Analytics::SmsInboundMessage, :count)
      end

      it "does not double-apply state changes" do
        described_class.call(sns_message: sns_message)
        first_timestamp = user.reload.sms_carrier_opted_out_at
        travel_to(1.hour.from_now) do
          described_class.call(sns_message: sns_message)
        end
        expect(user.reload.sms_carrier_opted_out_at).to be_within(1.second).of(first_timestamp)
      end
    end

    context "when the origination phone matches no user" do
      it "is still successful and persists the message" do
        expect { result }.to change(Analytics::SmsInboundMessage, :count).by(1)
        expect(result.errors).to be_empty
      end
    end

    context "when the origination phone matches multiple users" do
      let!(:user_a) { create(:user, phone: phone, phone_confirmed_at: Time.current) }
      let!(:user_b) { create(:user, phone: phone, phone_confirmed_at: Time.current) }

      it "updates all matching users" do
        result
        expect(user_a.reload.sms_carrier_opted_out_at).to be_present
        expect(user_b.reload.sms_carrier_opted_out_at).to be_present
      end
    end

    context "when the inner Message JSON is malformed" do
      let(:sns_message) do
        {
          "Type" => "Notification",
          "MessageId" => sns_message_id,
          "Timestamp" => received_at_str,
          "Message" => '{"originationNumber": "+13038806481"',
        }
      end

      before { allow(Rails.error).to receive(:report) }

      it "returns an unsuccessful response with a structured error" do
        expect(result).not_to be_successful
        expect(result.errors.first[:title]).to match(/SNS payload/)
      end

      it "does not create a record" do
        expect { result }.not_to change(Analytics::SmsInboundMessage, :count)
      end
    end

    context "when an inner-payload field is missing" do
      let(:inbound_payload) do
        { "originationNumber" => phone }
      end

      before { allow(Rails.error).to receive(:report) }

      it "returns an unsuccessful response and reports to Rails.error" do
        expect(result).not_to be_successful
        expect(Rails.error).to have_received(:report).with(instance_of(KeyError), handled: true, context: hash_including(:sns_message_id))
      end
    end
  end
end
