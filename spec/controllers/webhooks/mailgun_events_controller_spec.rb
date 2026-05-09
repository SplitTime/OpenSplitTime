require "rails_helper"

RSpec.describe Webhooks::MailgunEventsController do
  describe "#create" do
    subject(:make_request) { post :create, params: params, as: :json }

    before { allow(OstConfig).to receive(:mailgun_webhook_signing_key).and_return("test-signing-key") }

    let(:timestamp) { "1683409840" }
    let(:token) { "a1b2c3d4e5f6" }
    let(:signature) { OpenSSL::HMAC.hexdigest("SHA256", "test-signing-key", "#{timestamp}#{token}") }
    let(:signature_params) do
      {
        "timestamp" => timestamp,
        "token" => token,
        "signature" => signature,
      }
    end

    context "when a delivered event is received" do
      let(:params) do
        {
          "signature" => signature_params,
          "event-data" => {
            "event" => "delivered",
            "id" => "MXcc2gEpS-eN8HfkOnmK2w",
            "timestamp" => 1770146431.6585283,
            "recipient" => "recipient@sample.mailgun.com",
            "message" => {
              "headers" => {
                "message-id" => "20260203192030.53383e583ab41f62@sample.mailgun.com",
              },
            },
            "delivery-status" => {
              "code" => 250,
              "message" => "OK",
            },
          },
        }
      end

      it "returns a successful 200 response" do
        make_request
        expect(response.status).to eq(200)
      end

      it "creates a new mailgun event" do
        expect { make_request }.to change(Analytics::MailgunEvent, :count).by(1)
      end

      it "saves the event with correct attributes" do
        make_request
        event = Analytics::MailgunEvent.last
        expect(event.email).to eq("recipient@sample.mailgun.com")
        expect(event.event).to eq("delivered")
        expect(event.provider_event_id).to eq("MXcc2gEpS-eN8HfkOnmK2w")
        expect(event.provider_message_id).to eq("20260203192030.53383e583ab41f62@sample.mailgun.com")
        expect(event.status).to eq("250")
        expect(event.response).to eq("OK")
      end

      it "sets the STI type to Analytics::MailgunEvent" do
        make_request
        expect(Analytics::MailgunEvent.last.type).to eq("Analytics::MailgunEvent")
      end
    end

    context "when a failed event is received" do
      let(:params) do
        {
          "signature" => signature_params,
          "event-data" => {
            "event" => "failed",
            "id" => "2kFItcrLQuKTdp-Ia2Xr7w",
            "timestamp" => 1770918175.5923693,
            "recipient" => "badrecipient@sample.mailgun.com",
            "reason" => "bounce",
            "severity" => "permanent",
            "message" => {
              "headers" => {
                "message-id" => "20260212174255.58bbb7ce85a423e5@mailgun.com",
              },
            },
            "delivery-status" => {
              "code" => 550,
              "message" => "5.5.0 Requested action not taken: mailbox unavailable",
            },
          },
        }
      end

      it "saves the event with failure details" do
        make_request
        event = Analytics::MailgunEvent.last
        expect(event.event).to eq("failed")
        expect(event.reason).to eq("bounce")
        expect(event.status).to eq("550")
        expect(event.response).to eq("5.5.0 Requested action not taken: mailbox unavailable")
      end
    end

    context "when an opened event is received" do
      let(:params) do
        {
          "signature" => signature_params,
          "event-data" => {
            "event" => "opened",
            "id" => "q7DMpbLFRKW1QuiLC9XV4Q",
            "timestamp" => 1770327074.5549328,
            "recipient" => "recipient@sample.mailgun.com",
            "ip" => "38.142.208.162",
            "message" => {
              "headers" => {
                "message-id" => "20260205213049.8e3a7bf607f78309@sample.mailgun.com",
              },
            },
            "client-info" => {
              "user-agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
            },
          },
        }
      end

      it "saves the event with engagement details" do
        make_request
        event = Analytics::MailgunEvent.last
        expect(event.event).to eq("opened")
        expect(event.ip).to eq("38.142.208.162")
        expect(event.useragent).to eq("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)")
      end
    end

    context "when the signature is invalid" do
      let(:params) do
        {
          "signature" => {
            "timestamp" => timestamp,
            "token" => token,
            "signature" => "invalid-signature",
          },
          "event-data" => {
            "event" => "delivered",
            "id" => "abc123",
            "timestamp" => 1683409840,
            "recipient" => "user@example.com",
          },
        }
      end

      it "returns a 401 response" do
        make_request
        expect(response.status).to eq(401)
      end

      it "does not create a new record" do
        expect { make_request }.not_to(change(Analytics::MailgunEvent, :count))
      end
    end

    context "when event-data is missing" do
      let(:params) do
        {
          "signature" => signature_params,
        }
      end

      it "returns a 422 response" do
        make_request
        expect(response.status).to eq(422)
      end
    end
  end
end
