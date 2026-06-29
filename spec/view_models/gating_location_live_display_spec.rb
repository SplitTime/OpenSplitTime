require "rails_helper"

RSpec.describe GatingLocationLiveDisplay do
  let(:gating_location) { gating_locations(:sum_bandera_gate) }
  let(:gle_100k) { gating_location_events(:sum_bandera_gate_100k) }
  let(:gle_55k) { gating_location_events(:sum_bandera_gate_55k) }

  describe "#buffer_for" do
    context "without an adjustment" do
      subject(:display) { described_class.new(gating_location: gating_location) }

      it "returns each event's saved default" do
        expect(display.buffer_for(gle_100k)).to eq(gle_100k.default_travel_buffer)
        expect(display.buffer_for(gle_55k)).to eq(gle_55k.default_travel_buffer)
      end
    end

    context "when one event's buffer is adjusted" do
      subject(:display) do
        described_class.new(gating_location: gating_location, adjusted_event_id: gle_100k.id.to_s, adjusted_buffer: "90")
      end

      it "applies the adjusted value only to that event" do
        expect(display.buffer_for(gle_100k)).to eq(90)
        expect(display.buffer_for(gle_55k)).to eq(gle_55k.default_travel_buffer)
      end
    end

    context "when the adjusted buffer is out of range" do
      subject(:display) do
        described_class.new(gating_location: gating_location, adjusted_event_id: gle_100k.id.to_s, adjusted_buffer: "5000")
      end

      it "clamps to the maximum" do
        expect(display.buffer_for(gle_100k)).to eq(1200)
      end
    end
  end
end
