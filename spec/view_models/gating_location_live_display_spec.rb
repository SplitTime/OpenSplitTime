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

  describe "#rows_for" do
    # sum_100k_drop_anvil has a recorded time at the gating aid station, so it appears in the rows.
    let(:passed_effort) { efforts(:sum_100k_drop_anvil) }

    before { allow(Projection).to receive(:execute_query).and_return([]) }

    it "includes runners who have passed the gating aid station" do
      display = described_class.new(gating_location: gating_location)
      expect(display.rows_for(gle_100k).map(&:bib_number)).to include(passed_effort.bib_number)
    end

    context "when the crew has been marked passed" do
      before { gating_location.crew_passages.create!(effort: passed_effort, passed_at: Time.current) }

      it "marks that runner's row as passed" do
        display = described_class.new(gating_location: gating_location)
        row = display.rows_for(gle_100k).find { |r| r.bib_number == passed_effort.bib_number }
        expect(row.crew_passed?).to be(true)
      end

      it "hides passed crews when hide_passed is set for the event" do
        display = described_class.new(gating_location: gating_location, adjusted_event_id: gle_100k.id, hide_passed: "1")
        expect(display.rows_for(gle_100k).map(&:bib_number)).not_to include(passed_effort.bib_number)
      end
    end

    context "with a search term" do
      it "keeps only runners matching the bib or name" do
        display = described_class.new(gating_location: gating_location, adjusted_event_id: gle_100k.id,
                                      search: "no-such-runner-zzz")
        expect(display.rows_for(gle_100k)).to be_empty
      end
    end
  end
end
