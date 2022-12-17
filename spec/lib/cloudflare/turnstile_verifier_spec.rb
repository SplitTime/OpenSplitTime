# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Cloudflare::TurnstileVerifier do
  describe ".token_valid?" do
    let(:result) { described_class.token_valid?(token) }
    let(:token) { "fake.token" }
    let(:fake_response) { ::RestClient::Response.new }
    before { allow(RestClient).to receive(:post).and_return(fake_response) }

    it "sends a post request to turnstile with expected params" do
      expect(RestClient).to receive(:post).with(described_class::TURNSTILE_URL, anything)
      result
    end
  end
end
