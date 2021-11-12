# frozen_string_literal: true

require "rails_helper"

RSpec.describe IntervalSplitTraffic, type: :model do
  describe ".execute_query" do
    subject { described_class.execute_query(event_group: event_group, split_name: split_name, band_width: band_width) }
    let(:event_group) { event_groups(:hardrock_2015) }
    let(:band_width) { 1.hour }

    context "for a split close to the start" do
      let(:split_name) { "Cunningham" }

      it "returns an array of IntervalSplitTraffic objects" do
        expect(subject.size).to eq(3)
        expect(subject.map(&:start_time)).to eq(["2015-07-10 13:00:00", "2015-07-10 14:00:00", "2015-07-10 15:00:00"])
        expect(subject.map(&:end_time)).to eq(["2015-07-10 14:00:00", "2015-07-10 15:00:00", "2015-07-10 16:00:00"])
        expect(subject.map(&:total_in_count)).to eq([2, 20, 8])
        expect(subject.map(&:total_out_count)).to eq([2, 20, 8])
      end
    end

    context "for a split extending over multiple days" do
      let(:split_name) { "Telluride" }

      it "returns an array of IntervalSplitTraffic objects reflecting multiple days" do
        expect(subject.size).to eq(19)

        subject_ist = subject[10]
        expect(subject_ist.start_time).to eq("2015-07-11 13:00:00")
        expect(subject_ist.end_time).to eq("2015-07-11 14:00:00")
        expect(subject_ist.total_in_count).to eq(5)
        expect(subject_ist.total_finished_in_count).to eq(5)
        expect(subject_ist.total_out_count).to eq(4)
        expect(subject_ist.total_finished_out_count).to eq(4)
      end
    end

    context "for an event group with multiple events" do
      let(:event_group) { event_groups(:sum) }
      let(:split_name) { "Start" }
      let(:band_width) { 1.day }

      it "returns an array of IntervalSplitTraffic objects with counts for each event" do
        expect(subject.size).to eq(44)

        subject_ist = subject.first
        expect(subject_ist.start_time).to eq("2017-09-23 00:00:00")
        expect(subject_ist.end_time).to eq("2017-09-24 00:00:00")
        expect(subject_ist.short_names).to eq(["100K", "55K"])
        expect(subject_ist.event_ids).to eq([56, 57])
        expect(subject_ist.in_counts).to eq([2, 2])
        expect(subject_ist.out_counts).to eq([0, 0])
        expect(subject_ist.finished_in_counts).to eq([0, 2])
        expect(subject_ist.finished_out_counts).to eq([0, 0])
      end
    end

    context "when the query would return too many rows" do
      let(:split_name) { "Telluride" }
      let(:band_width) { 1.minute }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "for a split that has not yet seen any traffic" do
      let(:event_group) { event_groups(:hardrock_2016) }
      let(:split_name) { "Finish" }
      let(:split) { event_group.events.first.course.finish_split }
      before { event_group.split_times.where(split: split).each(&:destroy) }

      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end
  end

  describe "#counts_by_event" do
    subject do
      described_class.new(
        short_names: ["First Event", "Second Event"],
        event_ids: [1, 2],
        in_counts: [3, 4],
        out_counts: [3, 3],
        finished_in_counts: [2, 3],
        finished_out_counts: [2, 2],
        total_in_count: 7,
        total_out_count: 6,
        total_finished_in_count: 5,
        total_finished_out_count: 4,
      )
    end

    let(:result) { subject.counts_by_event }
    let(:expected_result) do
      {
        1 => described_class::Counts.new(1, "First Event", 3, 3, 2, 2),
        2 => described_class::Counts.new(2, "Second Event", 4, 3, 3, 2),
        nil => described_class::Counts.new(nil, nil, 7, 6, 5, 4),
      }
    end

    it "returns a hash with organized information" do
      expect(result).to eq(expected_result)
    end
  end
end
