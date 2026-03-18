require "rails_helper"

RSpec.describe EffortWithLapSplitRows do
  subject(:view_model) { described_class.new(effort) }

  let(:event) { events(:hardrock_2015) }
  let(:effort) { event.efforts.order(:bib_number).first }

  describe "#initialize" do
    context "when initialized with an effort" do
      it { expect { subject }.not_to raise_error }
    end

    context "when initialized without an effort" do
      let(:effort) { nil }

      it { expect { subject }.to raise_error ArgumentError, /must include effort/ }
    end
  end

  describe "#effort" do
    it "returns an effort" do
      expect(subject.effort).to be_a(Effort)
    end
  end

  describe "#event" do
    it "returns the effort's event" do
      expect(subject.event).to eq(event)
    end
  end

  describe "#lap_split_rows" do
    it "returns an array of LapSplitRow objects" do
      expect(subject.lap_split_rows).to all be_a(LapSplitRow)
    end

    it "returns rows matching the event splits" do
      expect(subject.lap_split_rows.size).to eq(event.ordered_splits.size)
    end
  end

  describe "#total_time_in_aid" do
    it "returns a numeric value" do
      expect(subject.total_time_in_aid).to be_a(Numeric)
    end
  end

  describe "#not_analyzable?" do
    context "when effort has two or more split_times" do
      it "returns false" do
        expect(subject.not_analyzable?).to be false
      end
    end
  end

  describe "#effort_start_time" do
    it "returns the effort's actual start time" do
      expect(subject.effort_start_time).to be_present
    end
  end

  describe "#true_lap_time" do
    it "returns a numeric value for lap 1" do
      result = subject.true_lap_time(1)
      expect(result).to be_a(Numeric)
    end
  end

  describe "#method_missing" do
    it "delegates unknown methods to effort" do
      expect(subject.full_name).to eq(subject.effort.full_name)
    end
  end
end
