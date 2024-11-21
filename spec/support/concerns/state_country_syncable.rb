# frozen_string_literal: true

RSpec.shared_examples_for "state_country_syncable" do
  let(:model) { described_class }
  let(:model_name) { model.name.underscore.to_sym }
  subject { build_stubbed(model_name, state_code: state_code, country_code: country_code) }
  let(:state_code) { "CO" }
  let(:country_code) { "US" }

  describe "before validation" do
    context "when state_code and country_code are blank" do
      let(:state_code) { nil }
      let(:country_code) { nil }

      it "makes no changes to state_name or country_name" do
        subject.run_callbacks(:save)
        expect(subject.state_name).to be_nil
        expect(subject.country_name).to be_nil
      end
    end

    context "when only state_code is blank" do
      let(:state_code) { nil }

      it "makes no changes to state_name but adds country_name" do
        subject.run_callbacks(:save)
        expect(subject.state_name).to be_nil
        expect(subject.country_name).to eq("United States")
      end
    end

    context "when only country_code is blank" do
      let(:country_code) { nil }

      it "makes no changes to state_name or country_name" do
        subject.run_callbacks(:save)
        expect(subject.state_name).to be_nil
        expect(subject.country_name).to be_nil
      end
    end

    context "when both state_code and country_code are updated" do
      it "resets state_name and country_name to match" do
        subject.run_callbacks(:save)
        expect(subject.state_name).to eq("Colorado")
        expect(subject.country_name).to eq("United States")

        subject.state_code = "BC"
        subject.country_code = "CA"

        subject.run_callbacks(:save)
        expect(subject.state_name).to eq("British Columbia")
        expect(subject.country_name).to eq("Canada")
      end
    end
  end
end
