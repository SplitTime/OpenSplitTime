# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Cloudflare::TurnstileVerifier do
  describe ".token_valid?" do
    let(:result) { described_class.token_valid?(token) }
    let(:token) { "fake.token" }
    let(:fake_response) { instance_double(::RestClient::Response, body: body.to_json) }

    let(:body) { { "success" => false } }

    before { allow(::RestClient).to receive(:post).and_return(fake_response) }

    it "sends a post request to turnstile with expected params" do
      expect(::RestClient).to receive(:post).with(described_class::TURNSTILE_URL, anything)
      result
    end

    context "when the response is successful" do
      let(:body) { { "success" => true } }

      it { expect(result).to eq(true) }
    end

    context "when the response is not successful" do
      let(:body) { { "success" => false } }

      it { expect(result).to eq(false) }
    end
  end
end
