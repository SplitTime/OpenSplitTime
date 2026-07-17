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

  describe "#crew_passed?" do
    it "is false without a crew passage" do
      expect(row.crew_passed?).to be(false)
    end

    it "is true when a crew passage is present" do
      passed_row = described_class.new(effort: effort, gating_location_event: gating_location_event,
                                       crew_passage: CrewPassage.new)
      expect(passed_row.crew_passed?).to be(true)
    end
  end

  context "when the runner has not reached the gating aid station" do
    it "is not gated and has no release time" do
      expect(row.passed_gating?).to be(false)
      expect(row.predicted_target_arrival).to be_nil
    end
  end

  context "when the runner has only checked In at a gating aid station that records an Out" do
    before do
      build_split_time(split: gating_split, bitkey: SubSplit::IN_BITKEY, absolute_time: gating_time)
    end

    it "is not yet gated and makes no release determination until the Out time is recorded" do
      expect(gating_split.out_bitkey).to be_present
      expect(row.passed_gating?).to be(false)
      expect(row.gating_split_time).to be_nil
      expect(row.predicted_target_arrival).to be_nil
    end
  end

  context "when the runner has departed the gating aid station" do
    before do
      build_split_time(split: gating_split, bitkey: SubSplit::IN_BITKEY, absolute_time: gating_time - 5.minutes)
      build_split_time(split: gating_split, bitkey: SubSplit::OUT_BITKEY, absolute_time: gating_time)
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
      expect(row.anchored_beyond_gate?).to be(false)
    end
  end

  # A gate far from its target, with intermediate aid stations in between, exercises the progressive
  # projection: the gate is only the earliest anchor, and the estimate re-anchors on the runner's
  # furthest recorded intermediate point.
  context "with intermediate aid stations between the gate and target" do
    subject(:row) { described_class.new(effort: effort, gating_location_event: wide_gate) }

    let(:update_release_times) { true }
    let(:wide_gate) do
      GatingLocationEvent.new(gating_location: gating_locations(:sum_bandera_gate), event: event,
                              gating_aid_station: aid_stations(:aid_station_0017), # Molas Pass, distance 18347
                              target_aid_station: aid_stations(:aid_station_0020), # Bandera Mine, distance 80741
                              default_travel_buffer: 60, update_release_times: update_release_times)
    end
    let(:gate_split) { splits(:sum_100k_course_molas_pass_aid1) }
    let(:intermediate_split) { splits(:sum_100k_course_cascade_creek_rd_aid3) } # distance 46317
    let(:beyond_intermediate_split) { splits(:sum_100k_course_engineer_mtn_th_aid4) } # distance 59642

    before { build_split_time(split: gate_split, bitkey: SubSplit::OUT_BITKEY, absolute_time: gating_time) }

    context "when the runner has reached an intermediate station" do
      before do
        build_split_time(split: intermediate_split, bitkey: SubSplit::OUT_BITKEY, absolute_time: gating_time + 2.hours)
        allow(Projection).to receive(:execute_query).and_return([instance_double(Projection, low_seconds: 3600)])
      end

      it "re-anchors the projection on the furthest intermediate point" do
        expect(row.anchored_beyond_gate?).to be(true)
        expect(row.projection_anchor_label).to eq(intermediate_split.base_name)
        # Projected from the intermediate time (gate + 2h), not the gate time.
        expect(row.predicted_target_arrival).to eq(gating_time + 2.hours + 3600.seconds)
      end

      it "flags the release as subject to change and lists the interim stations" do
        expect(row.release_may_update?).to be(true)
        expect(row.release_held_constant?).to be(false)
        expect(row.interim_split_names).to include(intermediate_split.base_name, beyond_intermediate_split.base_name)
      end
    end

    context "when the gate does not update release times" do
      let(:update_release_times) { false }

      before do
        build_split_time(split: intermediate_split, bitkey: SubSplit::OUT_BITKEY, absolute_time: gating_time + 2.hours)
        allow(Projection).to receive(:execute_query).and_return([instance_double(Projection, low_seconds: 3600)])
      end

      it "holds the release constant from the gating time, ignoring interim progress" do
        expect(row.anchored_beyond_gate?).to be(false)
        # Anchored on the gate time, not the intermediate (gate + 2h).
        expect(row.predicted_target_arrival).to eq(gating_time + 3600.seconds)
        expect(row.release_may_update?).to be(false)
        expect(row.release_held_constant?).to be(true)
      end

      it "still nullifies the release when the runner drops at an interim station" do
        allow(effort).to receive(:stopped?).and_return(true)
        expect(row.predicted_target_arrival).to be_nil
      end
    end

    context "when the furthest intermediate point has no prior-year data" do
      before do
        build_split_time(split: intermediate_split, bitkey: SubSplit::OUT_BITKEY, absolute_time: gating_time + 2.hours)
        build_split_time(split: beyond_intermediate_split, bitkey: SubSplit::IN_BITKEY,
                         absolute_time: gating_time + 3.hours)
        # No projection from the furthest point (Engineer Mtn); the intermediate (Cascade Creek) has data.
        allow(Projection).to receive(:execute_query) do |split_time:, **|
          projected = split_time.split_id == intermediate_split.id ? instance_double(Projection, low_seconds: 3600) : nil
          [projected].compact
        end
      end

      it "falls back to the nearest earlier point that has a projection" do
        expect(row.projection_anchor_label).to eq(intermediate_split.base_name)
        expect(row.predicted_target_arrival).to eq(gating_time + 2.hours + 3600.seconds)
      end
    end
  end
end
