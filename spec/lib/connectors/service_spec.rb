require "rails_helper"

RSpec.describe Connectors::Service do
  describe "#find" do
    let(:result) { described_class.find(identifier) }

    context "when the service exists" do
      let(:identifier) { "runsignup" }

      it "returns the service" do
        expect(result).to be_a(described_class)
        expect(result.name).to eq("RunSignup")
      end
    end

    context "when the service does not exist" do
      let(:identifier) { "nonexistent" }

      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end
end
