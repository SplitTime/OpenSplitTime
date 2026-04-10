require "rails_helper"

RSpec.describe Webhooks::MailgunEventsController do
  describe "#create" do
    subject(:make_request) { post :create, params: params, as: :json }

    before { allow(OstConfig).to receive(:mailgun_webhook_signing_key).and_return("test-signing-key") }

    let(:timestamp) { "1683409840" }
    let(:token) { "a1b2c3d4e5f6" }
    let(:signature) { OpenSSL::HMAC.hexdigest("SHA256", "test-signing-key", "#{timestamp}#{token}") }

    context "when the request is valid" do
      let(:params) do
        {
          "signature" => {
            "timestamp" => timestamp,
            "token" => token,
            "signature" => signature,
          },
          "event-data" => {
            "event" => "delivered",
            "id" => "MXcc2gEpS-eN8HfkOnmK2w",
            "timestamp" => 1683409840,
            "recipient" => "user@example.com",
            "message" => {
              "headers" => {
                "message-id" => "20230506.abc123@opensplittime.org",
              },
            },
            "ip" => "192.168.1.1",
            "reason" => nil,
            "client-info" => {
              "user-agent" => "Mozilla/5.0",
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
        expect(event.email).to eq("user@example.com")
        expect(event.event).to eq("delivered")
        expect(event.provider_event_id).to eq("MXcc2gEpS-eN8HfkOnmK2w")
        expect(event.provider_message_id).to eq("20230506.abc123@opensplittime.org")
        expect(event.ip).to eq("192.168.1.1")
        expect(event.useragent).to eq("Mozilla/5.0")
      end

      it "sets the STI type to Analytics::MailgunEvent" do
        make_request
        expect(Analytics::MailgunEvent.last.type).to eq("Analytics::MailgunEvent")
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

    context "when the request is missing event-data" do
      let(:params) do
        {
          "signature" => {
            "timestamp" => timestamp,
            "token" => token,
            "signature" => signature,
          },
        }
      end

      it "returns a 422 response" do
        make_request
        expect(response.status).to eq(422)
      end
    end
  end
end
