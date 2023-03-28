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

  describe ".fetch" do
    let(:result) { user.credentials.fetch(service_identifier, key) }
    let(:user) { users(:third_user) }
    let(:other_user) { users(:fourth_user) }
    let(:service_identifier) { "runsignup" }
    let(:key) { "api_key" }

    context "when a single record exists" do
      it "returns the value for the specified key" do
        expect(result).to eq("1234")
      end
    end

    context "when multiple records exist" do
      let(:result) { Credential.fetch(service_identifier, key) }
      before { described_class.create(user: other_user, service_identifier: service_identifier, key: key, value: "5678") }

      it "raises an error" do
        expect { result }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    context "when the service does not exist" do
      let(:service_identifier) { "foo" }

      it "returns nil" do
        expect(result).to be_nil
      end
    end

    context "when the key does not exist" do
      let(:key) { "foo" }

      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end
end
