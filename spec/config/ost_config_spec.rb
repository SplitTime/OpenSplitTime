require "rails_helper"

RSpec.describe OstConfig do
  describe ".cloudflare_analytics_enabled?" do
    subject { described_class.cloudflare_analytics_enabled? }

    before do
      allow(Rails.env).to receive(:production?).and_return(production)
      allow(described_class).to receive_messages(credentials_env: credentials_env, cloudflare_analytics_token: token)
    end

    context "when in production with a token and no staging override" do
      let(:production) { true }
      let(:credentials_env) { nil }
      let(:token) { "abc123" }

      it { is_expected.to be true }
    end

    context "when on staging (production env with CREDENTIALS_ENV=staging)" do
      let(:production) { true }
      let(:credentials_env) { "staging" }
      let(:token) { "abc123" }

      it { is_expected.to be false }
    end

    context "when in production without a token" do
      let(:production) { true }
      let(:credentials_env) { nil }
      let(:token) { nil }

      it { is_expected.to be_falsey }
    end

    context "when outside production" do
      let(:production) { false }
      let(:credentials_env) { nil }
      let(:token) { "abc123" }

      it { is_expected.to be false }
    end
  end
end
