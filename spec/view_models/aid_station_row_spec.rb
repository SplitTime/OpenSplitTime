require "rails_helper"

RSpec.describe AidStationRow do
  subject(:row) { described_class.new(aid_station: aid_station, event_framework: event_framework, split_times: split_times) }

  let(:event) { events(:hardrock_2015) }
  let(:split) { event.splits.find_by(kind: :intermediate) }
  let(:aid_station) { AidStation.new(event: event, split: split) }
  let(:event_framework) { nil }
  let(:split_times) { [] }

  describe "#initialize" do
    context "when initialized with an aid_station" do
      it { expect { subject }.not_to raise_error }
    end

    context "when initialized without an aid_station" do
      let(:aid_station) { nil }

      it { expect { subject }.to raise_error ArgumentError, /must include aid_station/ }
    end

    context "when initialized with default split_times" do
      let(:row) { described_class.new(aid_station: aid_station) }

      it { expect { row }.not_to raise_error }
    end
  end

  describe "#split_name" do
    it "returns the split base_name" do
      expect(subject.split_name).to eq(split.base_name)
    end
  end

  describe "#parameterized_split_name" do
    it "returns the parameterized base name" do
      expect(subject.parameterized_split_name).to eq(split.parameterized_base_name)
    end
  end

  describe "#category_sizes" do
    let(:event_framework) { LiveEventFramework.new(event: event) }
    let(:split_times) { event.split_times.where(split: split) }

    it "returns a hash with category keys and integer values" do
      result = subject.category_sizes
      expect(result).to be_a(Hash)
      expect(result.keys).to match_array(AidStationRow::AID_EFFORT_CATEGORIES)
      expect(result.values).to all be_a(Integer)
    end
  end

  describe "#category_table_titles" do
    let(:event_framework) { LiveEventFramework.new(event: event) }
    let(:split_times) { event.split_times.where(split: split) }

    it "returns a hash with category keys and string values" do
      result = subject.category_table_titles
      expect(result).to be_a(Hash)
      expect(result.keys).to match_array(AidStationRow::AID_EFFORT_CATEGORIES)
      expect(result.values).to all be_a(String)
    end
  end
end
