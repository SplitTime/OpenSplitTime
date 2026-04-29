require "rails_helper"

RSpec.describe Webhooks::SnsInboundController do
  let(:verifier) { instance_double(Aws::SNS::MessageVerifier) }
  let(:signature_valid) { true }

  before do
    allow(Aws::SNS::MessageVerifier).to receive(:new).and_return(verifier)
    allow(verifier).to receive(:authentic?).and_return(signature_valid)
  end

  def post_with_sns(body:, type:)
    request.headers["x-amz-sns-message-type"] = type
    post :create, body: body
  end

  describe "#create" do
    context "with an invalid SNS signature" do
      let(:signature_valid) { false }

      it "returns 401 and does not report to Rails.error" do
        allow(Rails.error).to receive(:report)
        post_with_sns(body: "{}", type: "Notification")
        expect(response).to have_http_status(:unauthorized)
        expect(Rails.error).not_to have_received(:report)
      end
    end

    context "with a SubscriptionConfirmation message and a valid AWS-host SubscribeURL" do
      let(:body) do
        {
          "Type" => "SubscriptionConfirmation",
          "MessageId" => "mid-1",
          "Token" => "token",
          "TopicArn" => "arn:aws:sns:us-west-2:186555151487:ost-sms-inbound",
          "SubscribeURL" => "https://sns.us-west-2.amazonaws.com/?Action=ConfirmSubscription&Token=...",
        }.to_json
      end

      before do
        allow(Net::HTTP).to receive(:get).and_return("ok")
      end

      it "returns 200 and fetches the SubscribeURL" do
        post_with_sns(body: body, type: "SubscriptionConfirmation")
        expect(response).to have_http_status(:ok)
        expect(Net::HTTP).to have_received(:get).with(URI("https://sns.us-west-2.amazonaws.com/?Action=ConfirmSubscription&Token=..."))
      end
    end

    context "with a SubscriptionConfirmation message and a non-AWS SubscribeURL" do
      let(:body) do
        {
          "Type" => "SubscriptionConfirmation",
          "MessageId" => "mid-1",
          "SubscribeURL" => "https://attacker.example.com/?Action=ConfirmSubscription",
        }.to_json
      end

      before do
        allow(Net::HTTP).to receive(:get)
        allow(Rails.error).to receive(:report)
      end

      it "returns 400, does not fetch the URL, and reports the anomaly" do
        post_with_sns(body: body, type: "SubscriptionConfirmation")
        expect(response).to have_http_status(:bad_request)
        expect(Net::HTTP).not_to have_received(:get)
        expect(Rails.error).to have_received(:report).with(
          an_instance_of(Webhooks::SmsWebhookError),
          handled: true,
        )
      end
    end

    context "with a Notification message" do
      let(:body) { { "Type" => "Notification", "MessageId" => "mid-1" }.to_json }

      context "when the interactor succeeds" do
        before do
          response_double = instance_double(Interactors::Response, successful?: true, errors: [])
          allow(Interactors::Webhooks::ProcessSnsInboundSms).to receive(:call).and_return(response_double)
        end

        it "returns 200" do
          post_with_sns(body: body, type: "Notification")
          expect(response).to have_http_status(:ok)
        end

        it "delegates to the interactor with the parsed sns_message" do
          post_with_sns(body: body, type: "Notification")
          expect(Interactors::Webhooks::ProcessSnsInboundSms).to have_received(:call).with(
            sns_message: hash_including("Type" => "Notification", "MessageId" => "mid-1"),
          )
        end
      end

      context "when the interactor fails" do
        before do
          response_double = instance_double(Interactors::Response, successful?: false, errors: [{ title: "bad" }])
          allow(Interactors::Webhooks::ProcessSnsInboundSms).to receive(:call).and_return(response_double)
        end

        it "returns 422 with errors in the body" do
          post_with_sns(body: body, type: "Notification")
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.parsed_body).to eq("errors" => [{ "title" => "bad" }])
        end
      end
    end

    context "with an UnsubscribeConfirmation message" do
      let(:body) do
        { "Type" => "UnsubscribeConfirmation", "TopicArn" => "arn:aws:sns:us-west-2:186555151487:ost-sms-inbound" }.to_json
      end

      before { allow(Rails.error).to receive(:report) }

      it "returns 200 (terminal — no AWS retry) and reports the anomaly" do
        post_with_sns(body: body, type: "UnsubscribeConfirmation")
        expect(response).to have_http_status(:ok)
        expect(Rails.error).to have_received(:report).with(
          an_instance_of(Webhooks::SmsWebhookError),
          handled: true,
        )
      end
    end

    context "with an unknown x-amz-sns-message-type header" do
      it "returns 400" do
        post_with_sns(body: "{}", type: "SomeUnknownType")
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
