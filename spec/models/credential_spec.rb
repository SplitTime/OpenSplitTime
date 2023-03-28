# frozen_string_literal: true

require "rails_helper"

RSpec.describe Credential do
  subject { build(:credential) }

  describe "scopes" do
    describe ".for_service" do
      let!(:credential) { create(:credential, service_identifier: service_identifier) }
      let(:service_identifier) { "runsignup" }

      it "returns credentials for the specified service_identifier" do
        expect(Credential.for_service(service_identifier)).to eq([credential])
      end
    end
  end
end
