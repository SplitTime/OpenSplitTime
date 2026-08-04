require "rails_helper"

RSpec.describe Results::EffortPerformanceDataAudit do
  describe ".stale_for_event?" do
    let(:event) { events(:hardrock_2015) }
    let(:effort) { efforts(:hardrock_2015_tuan_jacobs) }

    def perturb(effort, range, delta)
      bits = effort.overall_performance.to_s
      field = (bits[range].to_i(2) + delta).to_s(2).rjust(range.size, "0")
      perturbed = bits[0...range.begin] + field + bits[range.end..]
      effort.update_columns(overall_performance: perturbed)
    end

    it "is false when stored values match the current course" do
      expect(described_class.stale_for_event?(event)).to be(false)
    end

    it "is true when a stored distance no longer matches" do
      perturb(effort, 15...45, 1)
      expect(described_class.stale_for_event?(event)).to be(true)
    end

    it "is true when a stored lap no longer matches" do
      perturb(effort, 1...15, 1)
      expect(described_class.stale_for_event?(event)).to be(true)
    end

    it "ignores efforts with zeroed performance data" do
      effort.update_columns(overall_performance: "0" * 96, final_split_time_id: nil)
      expect(described_class.stale_for_event?(event)).to be(false)
    end
  end

  describe ".stale_event_ids" do
    let(:effort) { efforts(:hardrock_2015_tuan_jacobs) }

    it "returns only the event ids having stale efforts" do
      expect(described_class.stale_event_ids).to eq([])

      bits = effort.overall_performance.to_s
      field = (bits[15...45].to_i(2) + 1).to_s(2).rjust(30, "0")
      effort.update_columns(overall_performance: bits[0...15] + field + bits[45..])

      expect(described_class.stale_event_ids).to eq([effort.event_id])
    end
  end
end
