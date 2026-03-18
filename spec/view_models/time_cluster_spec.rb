require "rails_helper"
require "support/bitkey_definitions"

RSpec.describe TimeCluster do
  include BitkeyDefinitions

  subject(:cluster) { described_class.new(split_times_data: split_times_data, finish: finish, show_indicator_for_stop: show_indicator_for_stop) }

  let(:finish) { false }
  let(:show_indicator_for_stop) { false }

  let(:split_time_data_blank) { SplitTimeData.new }
  let(:split_time_data_1) do
    SplitTimeData.new(
      effort_id: 1, lap: 1, split_id: 10, bitkey: in_bitkey,
      time_from_start: 4000, segment_time: 4000,
      stopped_here: false, pacer: false, data_status_numeric: 2, id: 101,
    )
  end
  let(:split_time_data_2) do
    SplitTimeData.new(
      effort_id: 1, lap: 1, split_id: 10, bitkey: out_bitkey,
      time_from_start: 4100, segment_time: 100,
      stopped_here: false, pacer: true, data_status_numeric: 2, id: 102,
    )
  end
  let(:split_time_data_stopped) do
    SplitTimeData.new(
      effort_id: 1, lap: 1, split_id: 10, bitkey: in_bitkey,
      time_from_start: 5000, segment_time: 5000,
      stopped_here: true, pacer: false, data_status_numeric: 2, id: 103,
    )
  end

  describe "#initialize" do
    context "when initialized with all required arguments" do
      let(:split_times_data) { [split_time_data_1, split_time_data_2] }

      it { expect { subject }.not_to raise_error }
    end

    context "when initialized without split_times_data" do
      let(:split_times_data) { nil }

      it { expect { subject }.to raise_error ArgumentError, /must include split_times_data/ }
    end

    context "when finish is not provided" do
      subject(:cluster) { described_class.new(split_times_data: [split_time_data_1]) }

      it { expect { subject }.to raise_error ArgumentError }
    end
  end

  describe "#finish?" do
    let(:split_times_data) { [split_time_data_1] }

    context "when finish is true" do
      let(:finish) { true }

      it { expect(subject.finish?).to be true }
    end

    context "when finish is false" do
      let(:finish) { false }

      it { expect(subject.finish?).to be false }
    end
  end

  describe "#segment_time" do
    context "when split_times_data has two populated objects" do
      let(:split_times_data) { [split_time_data_1, split_time_data_2] }

      it "returns the segment_time of the first object" do
        expect(subject.segment_time).to eq(4000)
      end
    end

    context "when split_times_data has one populated and one blank object" do
      let(:split_times_data) { [split_time_data_1, split_time_data_blank] }

      it "returns the segment_time of the populated object" do
        expect(subject.segment_time).to eq(4000)
      end
    end

    context "when split_times_data has all blank objects" do
      let(:split_times_data) { [split_time_data_blank, split_time_data_blank] }

      it "returns nil" do
        expect(subject.segment_time).to be_nil
      end
    end
  end

  describe "#time_in_aid" do
    context "when split_times_data has two populated objects" do
      let(:split_times_data) { [split_time_data_1, split_time_data_2] }

      it "returns the segment_time of the last object" do
        expect(subject.time_in_aid).to eq(100)
      end
    end

    context "when split_times_data has a single object" do
      let(:split_times_data) { [split_time_data_1] }

      it "returns nil" do
        expect(subject.time_in_aid).to be_nil
      end
    end
  end

  describe "#times_from_start" do
    context "when split_times_data has two populated objects" do
      let(:split_times_data) { [split_time_data_1, split_time_data_2] }

      it "returns an array of times" do
        expect(subject.times_from_start).to eq([4000, 4100])
      end
    end

    context "when split_times_data has one populated and one blank object" do
      let(:split_times_data) { [split_time_data_1, split_time_data_blank] }

      it "returns an array with a time and nil" do
        expect(subject.times_from_start).to eq([4000, nil])
      end
    end
  end

  describe "#time_data_statuses" do
    let(:split_times_data) { [split_time_data_1, split_time_data_2] }

    it "returns an array of data statuses" do
      expect(subject.time_data_statuses).to eq(%w[good good])
    end
  end

  describe "#pacer_flags" do
    let(:split_times_data) { [split_time_data_1, split_time_data_2] }

    it "returns an array of pacer flags" do
      expect(subject.pacer_flags).to eq([false, true])
    end
  end

  describe "#stopped_here_flags" do
    let(:split_times_data) { [split_time_data_1, split_time_data_2] }

    it "returns an array of stopped_here flags" do
      expect(subject.stopped_here_flags).to eq([false, false])
    end
  end

  describe "#stopped_here?" do
    context "when no split_times are stopped" do
      let(:split_times_data) { [split_time_data_1, split_time_data_2] }

      it { expect(subject.stopped_here?).to be false }
    end

    context "when a split_time is stopped" do
      let(:split_times_data) { [split_time_data_stopped] }

      it { expect(subject.stopped_here?).to be true }
    end
  end

  describe "#show_stop_indicator?" do
    context "when stopped_here and show_indicator_for_stop are both true" do
      let(:split_times_data) { [split_time_data_stopped] }
      let(:show_indicator_for_stop) { true }

      it { expect(subject.show_stop_indicator?).to be true }
    end

    context "when stopped_here is true but show_indicator_for_stop is false" do
      let(:split_times_data) { [split_time_data_stopped] }
      let(:show_indicator_for_stop) { false }

      it { expect(subject.show_stop_indicator?).to be false }
    end

    context "when not stopped_here" do
      let(:split_times_data) { [split_time_data_1] }
      let(:show_indicator_for_stop) { true }

      it { expect(subject.show_stop_indicator?).to be false }
    end
  end

  describe "#aid_time_recordable?" do
    context "when split_times_data has multiple objects" do
      let(:split_times_data) { [split_time_data_1, split_time_data_2] }

      it { expect(subject.aid_time_recordable?).to be true }
    end

    context "when split_times_data has a single object" do
      let(:split_times_data) { [split_time_data_1] }

      it { expect(subject.aid_time_recordable?).to be false }
    end
  end

  describe "#split_time_ids" do
    let(:split_times_data) { [split_time_data_1, split_time_data_2] }

    it "returns an array of ids" do
      expect(subject.split_time_ids).to eq([101, 102])
    end
  end
end
