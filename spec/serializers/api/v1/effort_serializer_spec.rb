require "rails_helper"

RSpec.describe Api::V1::EffortSerializer do
  subject(:attributes) { described_class.new(effort, params: { current_user: current_user }).serializable_hash[:data][:attributes] }

  let(:effort) { build_stubbed(:effort, age: 45, person: person) }

  context "when the linked person has hide_age false" do
    let(:person) { build_stubbed(:person, hide_age: false) }
    let(:current_user) { nil }

    it "exposes age" do
      expect(attributes[:age]).to eq(45)
    end
  end

  context "when the effort has no linked person" do
    let(:person) { nil }
    let(:current_user) { nil }

    it "exposes age" do
      expect(attributes[:age]).to eq(45)
    end
  end

  context "when the linked person has hide_age true" do
    let(:person) { build_stubbed(:person, hide_age: true) }

    context "with no current_user" do
      let(:current_user) { nil }

      it "returns nil for age" do
        expect(attributes[:age]).to be_nil
      end
    end

    context "with a non-admin current_user" do
      let(:current_user) { build_stubbed(:user) }

      it "returns nil for age" do
        expect(attributes[:age]).to be_nil
      end
    end

    context "with an admin current_user" do
      let(:current_user) { build_stubbed(:admin) }

      it "exposes the real age" do
        expect(attributes[:age]).to eq(45)
      end
    end
  end
end
