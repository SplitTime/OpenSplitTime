require "rails_helper"

RSpec.describe EffortTimesRow do
  include BitkeyDefinitions

  subject(:row) { described_class.new(effort: effort, lap_splits: lap_splits, split_times: split_times, display_style: display_style) }

  let(:event) { events(:hardrock_2015) }
  let(:effort) { Effort.where(id: event.efforts.order(:bib_number).first.id).ranking_subquery.finish_info_subquery.first }
  let(:splits) { event.ordered_splits }
  let(:lap_splits) { event.lap_splits_through(1) }
  let(:split_times) { effort.ordered_split_times }
  let(:display_style) { "elapsed" }

  describe "#initialize" do
    context "when initialized with all required arguments" do
      it { expect { subject }.not_to raise_error }
    end

    context "when initialized without effort" do
      let(:effort) { nil }
      let(:split_times) { [] }

      it { expect { subject }.to raise_error ArgumentError, /must include effort/ }
    end

    context "when initialized without lap_splits" do
      let(:lap_splits) { nil }

      it { expect { subject }.to raise_error ArgumentError, /must include lap_splits/ }
    end

    context "when initialized without split_times" do
      let(:split_times) { nil }

      it { expect { subject }.to raise_error ArgumentError, /must include split_times/ }
    end
  end

  describe "#full_name" do
    it "delegates to effort" do
      expect(subject.full_name).to eq(effort.full_name)
    end
  end

  describe "#bib_number" do
    it "delegates to effort" do
      expect(subject.bib_number).to eq(effort.bib_number)
    end
  end

  describe "#time_clusters" do
    it "returns an array of TimeCluster objects with size matching lap_splits" do
      expect(subject.time_clusters.size).to eq(lap_splits.size)
      expect(subject.time_clusters).to all be_a(TimeCluster)
    end
  end

  describe "#total_time_in_aid" do
    it "returns a numeric value" do
      expect(subject.total_time_in_aid).to be_a(Numeric)
    end
  end

  describe "#total_segment_time" do
    it "returns a numeric value" do
      expect(subject.total_segment_time).to be_a(Numeric)
    end
  end

  describe "#show_elapsed_times?" do
    context "when display_style is 'elapsed'" do
      let(:display_style) { "elapsed" }

      it { expect(subject.show_elapsed_times?).to be true }
    end

    context "when display_style is 'all'" do
      let(:display_style) { "all" }

      it { expect(subject.show_elapsed_times?).to be true }
    end

    context "when display_style is 'segment'" do
      let(:display_style) { "segment" }

      it { expect(subject.show_elapsed_times?).to be false }
    end
  end

  describe "#show_absolute_times?" do
    context "when display_style is 'ampm'" do
      let(:display_style) { "ampm" }

      it { expect(subject.show_absolute_times?).to be true }
    end

    context "when display_style is 'military'" do
      let(:display_style) { "military" }

      it { expect(subject.show_absolute_times?).to be true }
    end

    context "when display_style is 'elapsed'" do
      let(:display_style) { "elapsed" }

      it { expect(subject.show_absolute_times?).to be false }
    end
  end

  describe "#show_segment_times?" do
    context "when display_style is 'segment'" do
      let(:display_style) { "segment" }

      it { expect(subject.show_segment_times?).to be true }
    end

    context "when display_style is 'elapsed'" do
      let(:display_style) { "elapsed" }

      it { expect(subject.show_segment_times?).to be false }
    end
  end

  describe "#show_pacer_flags?" do
    context "when display_style is 'all'" do
      let(:display_style) { "all" }

      it { expect(subject.show_pacer_flags?).to be true }
    end

    context "when display_style is 'elapsed'" do
      let(:display_style) { "elapsed" }

      it { expect(subject.show_pacer_flags?).to be false }
    end
  end

  describe "#elapsed_times" do
    it "returns an array of arrays" do
      expect(subject.elapsed_times).to be_a(Array)
      expect(subject.elapsed_times.size).to eq(lap_splits.size)
    end
  end

  describe "#segment_times" do
    it "returns an array of two-element arrays" do
      expect(subject.segment_times).to be_a(Array)
      expect(subject.segment_times.size).to eq(lap_splits.size)
      expect(subject.segment_times.first).to be_a(Array)
    end
  end
end
