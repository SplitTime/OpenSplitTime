# frozen_string_literal: true

require "rails_helper"

RSpec.describe Credential do
  describe "scopes" do
    describe ".for_service" do
      let(:result) { user.credentials.for_service(service_identifier) }
      let(:user) { users(:third_user) }
      let(:service_identifier) { "runsignup" }

      context "when credentials exist" do
        it "returns credentials for the specified service_identifier" do
          expect(result.count).to eq(2)
        end
      end

      context "when credentials do not exist" do
        let(:service_identifier) { "foo" }

        it "returns an empty collection" do
          expect(result.count).to eq(0)
        end
      end
    end
  end
end
