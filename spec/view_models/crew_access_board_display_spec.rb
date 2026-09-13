require "rails_helper"

RSpec.describe CrewAccessBoardDisplay do
  let(:gating_location) { gating_locations(:sum_bandera_gate) }
  let(:gle_100k) { gating_location_events(:sum_bandera_gate_100k) }

  describe "#buffer" do
    it "defaults to the gated event's saved travel buffer" do
      board = described_class.new(gating_location_event: gle_100k)
      expect(board.buffer).to eq(gle_100k.default_travel_buffer)
    end

    it "applies an adjusted value" do
      board = described_class.new(gating_location_event: gle_100k, buffer: "90")
      expect(board.buffer).to eq(90)
    end

    it "clamps an out-of-range value to the maximum" do
      board = described_class.new(gating_location_event: gle_100k, buffer: "5000")
      expect(board.buffer).to eq(1200)
    end
  end

  describe "#rows" do
    # sum_100k_drop_anvil has a recorded time at the gating aid station, so it appears in the rows.
    let(:passed_effort) { efforts(:sum_100k_drop_anvil) }

    before { allow(Projection).to receive(:execute_query).and_return([]) }

    it "includes runners who have passed the gating aid station" do
      board = described_class.new(gating_location_event: gle_100k)
      expect(board.rows.map(&:bib_number)).to include(passed_effort.bib_number)
    end

    context "when the crew has been marked passed" do
      before { gating_location.crew_passages.create!(effort: passed_effort, passed_at: Time.current) }

      it "marks that runner's row as passed" do
        board = described_class.new(gating_location_event: gle_100k)
        row = board.rows.find { |r| r.bib_number == passed_effort.bib_number }
        expect(row.crew_passed?).to be(true)
      end

      it "hides passed crews when hide_passed is set" do
        board = described_class.new(gating_location_event: gle_100k, hide_passed: "1")
        expect(board.rows.map(&:bib_number)).not_to include(passed_effort.bib_number)
      end
    end

    context "with a search term" do
      it "keeps only runners matching the bib or name" do
        board = described_class.new(gating_location_event: gle_100k, search: "no-such-runner-zzz")
        expect(board.rows).to be_empty
      end
    end
  end
end
