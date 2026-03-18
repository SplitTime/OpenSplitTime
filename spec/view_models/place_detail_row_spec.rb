require "rails_helper"

RSpec.describe PlaceDetailRow do
  subject(:row) do
    described_class.new(
      lap_split: lap_split,
      split_times: split_times,
      previous_lap_split: previous_lap_split,
      show_laps: show_laps,
      effort_name: effort_name,
      effort_ids_by_category: effort_ids_by_category,
    )
  end

  let(:course) { Course.new(name: "Test Course") }
  let(:split_1) { Split.new(course: course, base_name: "Start", distance_from_start: 0, sub_split_bitmap: 1, vert_gain_from_start: 0, vert_loss_from_start: 0, kind: :start) }
  let(:split_2) { Split.new(course: course, base_name: "Aid 1", distance_from_start: 10_000, sub_split_bitmap: 65, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: :intermediate) }
  let(:split_3) { Split.new(course: course, base_name: "Finish", distance_from_start: 20_000, sub_split_bitmap: 1, vert_gain_from_start: 500, vert_loss_from_start: 500, kind: :finish) }

  let(:lap_1_split_1) { LapSplit.new(1, split_1) }
  let(:lap_1_split_2) { LapSplit.new(1, split_2) }
  let(:lap_2_split_2) { LapSplit.new(2, split_2) }

  let(:lap_split) { lap_1_split_2 }
  let(:split_times) { [nil, nil] }
  let(:previous_lap_split) { lap_1_split_1 }
  let(:show_laps) { false }
  let(:effort_name) { "Jane Doe" }
  let(:effort_ids_by_category) do
    {
      passed_segment: [1, 2],
      passed_in_aid: [3],
      passed_by_segment: [4],
      passed_by_in_aid: [],
      together_in_aid: [5, 6, 7],
    }
  end

  describe "#initialize" do
    context "when initialized with a lap_split" do
      it { expect { subject }.not_to raise_error }
    end

    context "when initialized without a lap_split" do
      let(:lap_split) { nil }

      it { expect { subject }.to raise_error ArgumentError, /must include lap_split/ }
    end
  end

  describe "#name" do
    context "when show_laps is false" do
      let(:show_laps) { false }

      it "returns the name without lap" do
        expect(subject.name).to eq(lap_split.name_without_lap)
      end
    end

    context "when show_laps is true" do
      let(:lap_split) { lap_2_split_2 }
      let(:show_laps) { true }

      it "returns the name with lap" do
        expect(subject.name).to eq(lap_split.name)
      end
    end
  end

  describe "#encountered_ids" do
    it "returns combined passed_segment, passed_by_segment, and together_in_aid ids" do
      expect(subject.encountered_ids).to eq([1, 2, 4, 5, 6, 7])
    end
  end

  describe "#passed_segment_ids" do
    it "returns ids from the category hash" do
      expect(subject.passed_segment_ids).to eq([1, 2])
    end
  end

  describe "#together_in_aid_ids" do
    it "returns ids from the category hash" do
      expect(subject.together_in_aid_ids).to eq([5, 6, 7])
    end
  end

  describe "#passed_segment_table_title" do
    it "returns a descriptive string including the effort name and count" do
      result = subject.passed_segment_table_title
      expect(result).to include("Jane Doe")
      expect(result).to include("passed")
      expect(result).to include("2 people")
    end
  end
end
