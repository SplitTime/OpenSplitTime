# frozen_string_literal: true

require "rails_helper"

RSpec.describe Webhooks::SendgridEventsController do
  describe "#create" do
    subject(:make_request) { post :create, params: params }

    before { allow_any_instance_of(described_class).to receive(:valid_webhook_token?).and_return(true) }

    context "when the request is valid" do
      let(:params) do
        {
          "_json" => [
            { "email" => "example@test.com", "timestamp" => 1683409840, "smtp_id" => "<14c5d75ce93.dfd.64b469@ismtpd-555>", "event" => "processed", "category" => ["cat facts"], "sg_event_id" => "X8wfWWCzIxX8tMWL7sjY5w==", "sg_message_id" => "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0" },
            { "email" => "example@test.com", "timestamp" => 1683409840, "smtp_id" => "<14c5d75ce93.dfd.64b469@ismtpd-555>", "event" => "deferred", "category" => ["cat facts"], "sg_event_id" => "AU2Pbl6mI0yLBcl_i6QkNg==", "sg_message_id" => "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0", "response" => "400 try again later", "attempt" => "5" },
            { "email" => "example@test.com", "timestamp" => 1683409840, "smtp_id" => "<14c5d75ce93.dfd.64b469@ismtpd-555>", "event" => "delivered", "category" => ["cat facts"], "sg_event_id" => "pqMBbPzdxlY4McLbcamlyw==", "sg_message_id" => "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0", "response" => "250 OK" },
            { "email" => "example@test.com", "timestamp" => 1683409840, "smtp_id" => "<14c5d75ce93.dfd.64b469@ismtpd-555>", "event" => "open", "category" => ["cat facts"], "sg_event_id" => "lGi6FSk2GIpK8ICy2vOBPw==", "sg_message_id" => "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0", "useragent" => "Mozilla/4.0 (compatible; MSIE 6.1; Windows XP; .NET CLR 1.1.4322; .NET CLR 2.0.50727)", "ip" => "255.255.255.255" },
            { "email" => "example@test.com", "timestamp" => 1683409840, "smtp_id" => "<14c5d75ce93.dfd.64b469@ismtpd-555>", "event" => "click", "category" => ["cat facts"], "sg_event_id" => "4NyqZN1cQaOtLuNewnsVAA==", "sg_message_id" => "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0", "useragent" => "Mozilla/4.0 (compatible; MSIE 6.1; Windows XP; .NET CLR 1.1.4322; .NET CLR 2.0.50727)", "ip" => "255.255.255.255", "url" => "http://www.sendgrid.com/" },
            { "email" => "example@test.com", "timestamp" => 1683409840, "smtp_id" => "<14c5d75ce93.dfd.64b469@ismtpd-555>", "event" => "bounce", "category" => ["cat facts"], "sg_event_id" => "RA1JyjEqP7jVzIZmBcljjQ==", "sg_message_id" => "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0", "reason" => "500 unknown recipient", "status" => "5.0.0", "type" => "bounced" },
            { "email" => "example@test.com", "timestamp" => 1683409840, "smtp_id" => "<14c5d75ce93.dfd.64b469@ismtpd-555>", "event" => "dropped", "category" => ["cat facts"], "sg_event_id" => "AvE7XKIHRgmaaFFeIiI-4Q==", "sg_message_id" => "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0", "reason" => "Bounced Address", "status" => "5.0.0" },
            { "email" => "example@test.com", "timestamp" => 1683409840, "smtp_id" => "<14c5d75ce93.dfd.64b469@ismtpd-555>", "event" => "spamreport", "category" => ["cat facts"], "sg_event_id" => "8d3NZA6Z1kW0AMvY_M3vwA==", "sg_message_id" => "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0" },
            { "email" => "example@test.com", "timestamp" => 1683409840, "smtp_id" => "<14c5d75ce93.dfd.64b469@ismtpd-555>", "event" => "unsubscribe", "category" => ["cat facts"], "sg_event_id" => "6vWZmy42HQKbOKYIZNV52w==", "sg_message_id" => "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0" },
            { "email" => "example@test.com", "timestamp" => 1683409840, "smtp_id" => "<14c5d75ce93.dfd.64b469@ismtpd-555>", "event" => "group_unsubscribe", "category" => ["cat facts"], "sg_event_id" => "uEJBetZyOuZyEXrtbNPTmg==", "sg_message_id" => "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0", "useragent" => "Mozilla/4.0 (compatible; MSIE 6.1; Windows XP; .NET CLR 1.1.4322; .NET CLR 2.0.50727)", "ip" => "255.255.255.255", "url" => "http://www.sendgrid.com/", "asm_group_id" => 10 },
            { "email" => "example@test.com", "timestamp" => 1683409840, "smtp_id" => "<14c5d75ce93.dfd.64b469@ismtpd-555>", "event" => "group_resubscribe", "category" => ["cat facts"], "sg_event_id" => "48uaslePyuuE7YEzQbu6nA==", "sg_message_id" => "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0", "useragent" => "Mozilla/4.0 (compatible; MSIE 6.1; Windows XP; .NET CLR 1.1.4322; .NET CLR 2.0.50727)", "ip" => "255.255.255.255", "url" => "http://www.sendgrid.com/", "asm_group_id" => 10 },
          ]
        }
      end

      it "returns a successful 200 response" do
        make_request
        expect(response.status).to eq(200)
      end

      it "creates a new event for each row" do
        expect { make_request }.to change { SendgridEvent.count }.by(11)
      end

      it "saves type as the event type" do
        make_request
        sendgrid_event = SendgridEvent.find_by(event: "bounce")
        expect(sendgrid_event.event_type).to eq("bounced")
      end
    end

    context "when the request appears valid but lacks a required attribute" do
      let(:params) do
        {
          "_json" => [
            { "email" => "example@test.com", "timestamp" => nil, "smtp_id" => "<14c5d75ce93.dfd.64b469@ismtpd-555>", "event" => "processed", "category" => ["cat facts"], "sg_event_id" => "X8wfWWCzIxX8tMWL7sjY5w==", "sg_message_id" => "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0" },
          ]
        }
      end

      it "returns a 422 response" do
        make_request
        expect(response.status).to eq(422)
      end

      it "does not create a new record" do
        expect { make_request }.to_not change { SendgridEvent.count }
      end
    end

    context "when the request is invalid" do
      let(:params) { { not: "valid" } }

      it "returns a 422 response" do
        make_request
        expect(response.status).to eq(422)
      end
    end
  end
end
