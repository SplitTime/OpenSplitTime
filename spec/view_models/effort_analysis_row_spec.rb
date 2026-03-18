require "rails_helper"
require "support/bitkey_definitions"

RSpec.describe EffortAnalysisRow do
  include BitkeyDefinitions

  subject(:row) do
    described_class.new(
      lap_split: lap_split,
      split_times: split_times,
      typical_split_times: typical_split_times,
      start_time: start_time,
      show_laps: show_laps,
      prior_lap_split: prior_lap_split,
      prior_split_time: prior_split_time,
    )
  end

  let(:course) { Course.new(name: "Test Course") }
  let(:split_start) do
    Split.new(course: course, base_name: "Start", distance_from_start: 0,
              sub_split_bitmap: 1, vert_gain_from_start: 0, vert_loss_from_start: 0, kind: :start)
  end
  let(:split_aid) do
    Split.new(course: course, base_name: "Aid 1", distance_from_start: 10_000,
              sub_split_bitmap: 65, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: :intermediate)
  end
  let(:split_finish) do
    Split.new(course: course, base_name: "Finish", distance_from_start: 20_000,
              sub_split_bitmap: 1, vert_gain_from_start: 500, vert_loss_from_start: 500, kind: :finish)
  end

  let(:lap_split_start) { LapSplit.new(1, split_start) }
  let(:lap_split_aid) { LapSplit.new(1, split_aid) }
  let(:lap_split_finish) { LapSplit.new(1, split_finish) }

  let(:start_time) { Time.zone.parse("2015-07-01 06:00:00") }
  let(:show_laps) { false }
  let(:prior_lap_split) { lap_split_start }
  let(:prior_split_time) { nil }

  let(:split_time_in) do
    SplitTimeData.new(
      effort_id: 1, lap: 1, split_id: split_aid.id, bitkey: in_bitkey,
      time_from_start: 4000, segment_time: 4000, data_status_numeric: 2,
    )
  end
  let(:split_time_out) do
    SplitTimeData.new(
      effort_id: 1, lap: 1, split_id: split_aid.id, bitkey: out_bitkey,
      time_from_start: 4200, segment_time: 200, data_status_numeric: 2,
    )
  end
  let(:typical_in) do
    SplitTimeData.new(
      effort_id: nil, lap: 1, split_id: split_aid.id, bitkey: in_bitkey,
      time_from_start: 3800, segment_time: 3800, data_status_numeric: 2,
    )
  end
  let(:typical_out) do
    SplitTimeData.new(
      effort_id: nil, lap: 1, split_id: split_aid.id, bitkey: out_bitkey,
      time_from_start: 3900, segment_time: 100, data_status_numeric: 2,
    )
  end

  let(:lap_split) { lap_split_aid }
  let(:split_times) { [split_time_in, split_time_out] }
  let(:typical_split_times) { [typical_in, typical_out] }

  describe "#initialize" do
    context "when initialized with all required arguments" do
      it { expect { subject }.not_to raise_error }
    end

    context "when initialized without lap_split" do
      let(:lap_split) { nil }

      it { expect { subject }.to raise_error ArgumentError, /must include lap_split/ }
    end

    context "when initialized without split_times" do
      let(:split_times) { nil }

      it { expect { subject }.to raise_error ArgumentError, /must include split_times/ }
    end

    context "when initialized without typical_split_times" do
      let(:typical_split_times) { nil }

      it { expect { subject }.to raise_error ArgumentError, /must include typical_split_times/ }
    end

    context "when initialized without start_time" do
      let(:start_time) { nil }

      it { expect { subject }.to raise_error ArgumentError, /must include start_time/ }
    end
  end

  describe "#name" do
    context "when show_laps is false" do
      let(:show_laps) { false }

      it "returns the base name without lap" do
        expect(subject.name).to eq(lap_split.base_name_without_lap)
      end
    end

    context "when show_laps is true" do
      let(:show_laps) { true }

      it "returns the base name with lap" do
        expect(subject.name).to eq(lap_split.base_name)
      end
    end
  end

  describe "#time_cluster" do
    it "returns a TimeCluster" do
      expect(subject.time_cluster).to be_a(TimeCluster)
    end
  end

  describe "#typical_time_cluster" do
    it "returns a TimeCluster" do
      expect(subject.typical_time_cluster).to be_a(TimeCluster)
    end
  end

  describe "#segment_time" do
    it "returns the segment time from the time cluster" do
      expect(subject.segment_time).to eq(4000)
    end
  end

  describe "#time_in_aid" do
    it "returns the time in aid from the time cluster" do
      expect(subject.time_in_aid).to eq(200)
    end
  end

  describe "#combined_time" do
    it "returns segment_time plus time_in_aid" do
      expect(subject.combined_time).to eq(4200)
    end
  end

  describe "#segment_time_typical" do
    it "returns the typical segment time" do
      expect(subject.segment_time_typical).to eq(3800)
    end
  end

  describe "#time_in_aid_typical" do
    it "returns the typical time in aid" do
      expect(subject.time_in_aid_typical).to eq(100)
    end
  end

  describe "#combined_time_typical" do
    it "returns typical segment_time plus typical time_in_aid" do
      expect(subject.combined_time_typical).to eq(3900)
    end
  end

  describe "#segment_time_over_under" do
    it "returns the difference between actual and typical segment times" do
      expect(subject.segment_time_over_under).to eq(200)
    end

    context "when segment_time is nil" do
      let(:split_times) { [SplitTimeData.new, SplitTimeData.new] }

      it "returns nil" do
        expect(subject.segment_time_over_under).to be_nil
      end
    end
  end

  describe "#time_in_aid_over_under" do
    it "returns the difference between actual and typical time in aid" do
      expect(subject.time_in_aid_over_under).to eq(100)
    end
  end

  describe "#split_id" do
    it "returns the split id" do
      expect(subject.split_id).to eq(split_aid.id)
    end
  end

  describe "#intermediate?" do
    context "when the split is intermediate" do
      let(:lap_split) { lap_split_aid }

      it { expect(subject.intermediate?).to be true }
    end

    context "when the split is finish" do
      let(:lap_split) { lap_split_finish }

      it { expect(subject.intermediate?).to be false }
    end
  end

  describe "#finish?" do
    context "when the split is finish" do
      let(:lap_split) { lap_split_finish }

      it { expect(subject.finish?).to be true }
    end

    context "when the split is intermediate" do
      let(:lap_split) { lap_split_aid }

      it { expect(subject.finish?).to be false }
    end
  end
end
