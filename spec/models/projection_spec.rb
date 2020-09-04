# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Projection, type: :model do
  describe ".execute_query" do
    subject { described_class.execute_query(split_time, starting_time_point, subject_time_points) }
    let(:split_time) { effort.ordered_split_times.last }
    let(:effort) { efforts(:hardrock_2016_rene_mclaughlin) }
    let(:time_points) { effort.event.required_time_points }
    let(:starting_time_point) { time_points.first }
    let(:subject_time_points) { time_points.last(2) }

    context "when given valid arguments" do
      it "returns rows containing projected ratios and seconds" do
        expect(subject.size).to eq(2)

        projection = subject.first
        expect(projection.time_point).to eq(subject_time_points.first)
        expect(projection.low_ratio).to be_within(0.05).of(0.30)
        expect(projection.average_ratio).to be_within(0.05).of(0.35)
        expect(projection.high_ratio).to be_within(0.05).of(0.40)
        expect(projection.low_seconds).to be_within(100).of(33_100)
        expect(projection.average_seconds).to be_within(100).of(40_600)
        expect(projection.high_seconds).to be_within(100).of(48_200)
      end
    end

    context "when given a starting split time" do
      let(:split_time) { effort.ordered_split_times.first }
      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "when given no subject time points" do
      let(:subject_time_points) { [] }
      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end
  end

  describe "#time_point" do
    subject { described_class.new(lap: lap, split_id: split_id, sub_split_bitkey: bitkey) }
    let(:lap) { 1 }
    let(:split_id) { 2 }
    let(:bitkey) { out_bitkey }
    it "returns a TimePoint with expected values" do
      expect(subject.time_point).to eq(::TimePoint.new(lap, split_id, bitkey))
    end
  end
end
