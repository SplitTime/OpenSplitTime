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

  context "when the linked person has obscure_name true" do
    let(:effort) { build_stubbed(:effort, first_name: "Mark", last_name: "Oveson", person: person) }
    let(:person) { build_stubbed(:person, obscure_name: true) }

    context "with no current_user" do
      let(:current_user) { nil }

      it "returns initials for name fields" do
        expect(attributes[:firstName]).to eq("M.")
        expect(attributes[:lastName]).to eq("O.")
        expect(attributes[:fullName]).to eq("M. O.")
      end
    end

    context "with an admin current_user" do
      let(:current_user) { build_stubbed(:admin) }

      it "exposes the real name fields" do
        expect(attributes[:firstName]).to eq("Mark")
        expect(attributes[:lastName]).to eq("Oveson")
        expect(attributes[:fullName]).to eq("Mark Oveson")
      end
    end
  end

  context "when the effort has no linked person and name fields are set" do
    let(:effort) { build_stubbed(:effort, first_name: "Mark", last_name: "Oveson", person: nil) }
    let(:current_user) { nil }

    it "exposes real name fields" do
      expect(attributes[:firstName]).to eq("Mark")
      expect(attributes[:fullName]).to eq("Mark Oveson")
    end
  end
end
