require "rails_helper"

RSpec.describe GatingLocationRow do
  subject(:row) { described_class.new(effort: effort, gating_location_event: gating_location_event) }

  let(:gating_location_event) { gating_location_events(:sum_bandera_gate_100k) }
  let(:event) { gating_location_event.event }
  let(:gating_split) { gating_location_event.gating_split }
  let(:target_split) { gating_location_event.target_split }
  let(:effort) { event.efforts.build(first_name: "Test", last_name: "Runner", gender: "male", bib_number: 999) }
  let(:gating_time) { Time.zone.parse("2017-07-01 12:00:00") }

  before { Rails.cache.clear }

  def build_split_time(split:, bitkey:, absolute_time:, lap: 1)
    effort.split_times.build(split: split, lap: lap, sub_split_bitkey: bitkey, absolute_time: absolute_time)
  end

  context "when the runner has not reached the gating aid station" do
    it "is not gated and has no release time" do
      expect(row.passed_gating?).to be(false)
      expect(row.predicted_target_arrival).to be_nil
    end
  end

  context "when the runner has reached the gating aid station" do
    before do
      build_split_time(split: gating_split, bitkey: SubSplit::IN_BITKEY, absolute_time: gating_time)
      allow(Projection).to receive(:execute_query).and_return([instance_double(Projection, low_seconds: 3600)])
    end

    it "predicts target arrival as the gating time plus the projection low estimate" do
      expect(row.passed_gating?).to be(true)
      expect(row.predicted_target_arrival).to eq(gating_time + 3600.seconds)
    end

    it "computes the release time as the predicted arrival minus the buffer" do
      expect(row.release_time(30)).to eq(gating_time + 3600.seconds - 30.minutes)
    end

    context "when the runner is stopped" do
      before { allow(effort).to receive(:stopped?).and_return(true) }

      it "has no release time" do
        expect(row.predicted_target_arrival).to be_nil
      end
    end

    context "when the runner has an In time at the target aid station" do
      before { build_split_time(split: target_split, bitkey: SubSplit::IN_BITKEY, absolute_time: gating_time + 1.hour) }

      it "is reached but not departed, and has no release time" do
        expect(row.reached_target?).to be(true)
        expect(row.departed_target?).to be(false)
        expect(row.target_progress_time_local).to eq(gating_time + 1.hour)
        expect(row.predicted_target_arrival).to be_nil
      end
    end

    context "when the runner has departed the target aid station" do
      before do
        build_split_time(split: target_split, bitkey: SubSplit::IN_BITKEY, absolute_time: gating_time + 1.hour)
        build_split_time(split: target_split, bitkey: SubSplit::OUT_BITKEY, absolute_time: gating_time + 70.minutes)
      end

      it "is marked departed, labelled by the most recent split, and has no release time" do
        expect(row.departed_target?).to be(true)
        expect(row.target_progress_label).to eq("Departed #{target_split.base_name}")
        expect(row.target_progress_time_local).to eq(gating_time + 70.minutes)
        expect(row.predicted_target_arrival).to be_nil
      end
    end
  end

  context "when both IN and OUT times exist at the gating aid station" do
    before do
      build_split_time(split: gating_split, bitkey: SubSplit::IN_BITKEY, absolute_time: gating_time)
      build_split_time(split: gating_split, bitkey: SubSplit::OUT_BITKEY, absolute_time: gating_time + 5.minutes)
      allow(Projection).to receive(:execute_query).and_return([instance_double(Projection, low_seconds: 0)])
    end

    it "anchors on the OUT time" do
      expect(row.gating_split_time.bitkey).to eq(SubSplit::OUT_BITKEY)
      expect(row.predicted_target_arrival).to eq(gating_time + 5.minutes)
    end
  end
end
