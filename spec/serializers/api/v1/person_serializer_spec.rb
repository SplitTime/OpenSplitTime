require "rails_helper"

RSpec.describe Api::V1::PersonSerializer do
  subject(:attributes) { described_class.new(person, params: { current_user: current_user }).serializable_hash[:data][:attributes] }

  let(:person) { build_stubbed(:person, birthdate: 40.years.ago.to_date, hide_age: hide_age) }

  context "when hide_age is false" do
    let(:hide_age) { false }
    let(:current_user) { nil }

    it "exposes currentAge" do
      expect(attributes[:currentAge]).to eq(40)
    end
  end

  context "when hide_age is true" do
    let(:hide_age) { true }

    context "with no current_user" do
      let(:current_user) { nil }

      it "returns nil for currentAge" do
        expect(attributes[:currentAge]).to be_nil
      end
    end

    context "with a non-admin current_user" do
      let(:current_user) { build_stubbed(:user) }

      it "returns nil for currentAge" do
        expect(attributes[:currentAge]).to be_nil
      end
    end

    context "with an admin current_user" do
      let(:current_user) { build_stubbed(:admin) }

      it "exposes the real currentAge" do
        expect(attributes[:currentAge]).to eq(40)
      end
    end
  end
end
