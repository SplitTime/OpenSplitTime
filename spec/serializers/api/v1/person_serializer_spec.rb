require "rails_helper"

RSpec.describe Api::V1::PersonSerializer do
  subject(:attributes) { described_class.new(person, params: { current_user: current_user }).serializable_hash[:data][:attributes] }

  let(:person) do
    build_stubbed(:person,
                  birthdate: 40.years.ago.to_date,
                  first_name: "Mark",
                  last_name: "Oveson",
                  hide_age: hide_age,
                  obscure_name: obscure_name)
  end
  let(:hide_age) { false }
  let(:obscure_name) { false }

  context "when hide_age is false" do
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

  context "when obscure_name is false" do
    let(:current_user) { nil }

    it "exposes real name fields" do
      expect(attributes[:firstName]).to eq("Mark")
      expect(attributes[:lastName]).to eq("Oveson")
      expect(attributes[:fullName]).to eq("Mark Oveson")
    end
  end

  context "when obscure_name is true" do
    let(:obscure_name) { true }

    context "with no current_user" do
      let(:current_user) { nil }

      it "returns initials for name fields" do
        expect(attributes[:firstName]).to eq("M.")
        expect(attributes[:lastName]).to eq("O.")
        expect(attributes[:fullName]).to eq("M. O.")
      end
    end

    context "with a non-admin current_user" do
      let(:current_user) { build_stubbed(:user) }

      it "returns initials for name fields" do
        expect(attributes[:firstName]).to eq("M.")
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
end
