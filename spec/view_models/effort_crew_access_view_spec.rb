require "rails_helper"

RSpec.describe EffortCrewAccessView do
  before { allow(Projection).to receive(:execute_query).and_return([]) }

  context "when the effort's event is gated" do
    subject(:view) { described_class.new(efforts(:sum_100k_drop_anvil)) }

    it "builds a gating row for each gating location event of the event" do
      expect(view.gating_location_events).to all(be_a(GatingLocationEvent))
      expect(view.gating_rows.size).to eq(view.gating_location_events.size)
      expect(view.gating_rows).to all(be_a(GatingLocationRow))
    end
  end

  context "when the effort's event is not gated" do
    subject(:view) { described_class.new(efforts(:ggd30_50k_bad_finish)) }

    it "has no gating rows" do
      expect(view.gating_location_events).to be_empty
      expect(view.gating_rows).to be_empty
    end
  end
end
