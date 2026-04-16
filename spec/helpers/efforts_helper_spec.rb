require "rails_helper"

RSpec.describe EffortsHelper do
  describe "#last_reported_location" do
    # EffortRow is a SimpleDelegator, so instance_double can't verify delegator-forwarded methods.
    let(:effort_row) do
      double("EffortRow", # rubocop:disable RSpec/VerifiedDoubles
             started?: started,
             final_lap_split_name: "Aid 3",
             final_distance: final_distance)
    end
    let(:started) { true }

    context "when the effort has not started" do
      let(:started) { false }
      let(:final_distance) { nil }

      it "returns the placeholder" do
        expect(helper.last_reported_location(effort_row)).to eq("--")
      end
    end

    context "when the effort has started but final_distance is nil" do
      let(:final_distance) { nil }

      it "returns the split name only, without raising" do
        expect { helper.last_reported_location(effort_row) }.not_to raise_error
        expect(helper.last_reported_location(effort_row)).to eq("Aid 3")
      end
    end
  end
end
