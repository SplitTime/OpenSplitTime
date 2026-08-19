require "rails_helper"

RSpec.describe FindNotExpectedBibs do
  subject { described_class.perform(event_group, split_name) }

  let(:event_group) { event_groups(:hardrock_2015) }

  context "when the split name is valid for the event group" do
    let(:split_name) { "Sherman" }

    it "returns bib numbers without errors" do
      expect(subject.errors).to be_empty
      expect(subject.bib_numbers).to be_an(Array)
    end
  end

  context "when the split name is not found in the event group" do
    let(:split_name) { "Nonexistent" }

    it "returns an invalid split name error" do
      expect(subject.errors.first[:title]).to eq("Invalid split name")
      expect(subject.bib_numbers).to eq([])
    end
  end

  context "when the split name is nil" do
    let(:split_name) { nil }

    it "returns an invalid split name error instead of raising" do
      expect { subject }.not_to raise_error
      expect(subject.errors.first[:title]).to eq("Invalid split name")
      expect(subject.bib_numbers).to eq([])
    end
  end
end
