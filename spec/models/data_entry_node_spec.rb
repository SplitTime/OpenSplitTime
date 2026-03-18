require "rails_helper"
require "support/concerns/locatable"

RSpec.describe DataEntryNode do
  subject { described_class.new(**attributes) }

  let(:attributes) do
    { split_name: "Split Name",
      parameterized_split_name: "split-name",
      sub_split_kind: "in",
      label: "label",
      latitude: 40,
      longitude: -105,
      min_distance_from_start: 0 }
  end
  it_behaves_like "locatable"

  describe "#to_h" do
    it "returns all attributes in a Hash" do
      expect(subject.to_h).to eq(attributes)
    end
  end

  describe "#split_name" do
    it "returns the split_name" do
      expect(subject.split_name).to eq("Split Name")
    end
  end
end
