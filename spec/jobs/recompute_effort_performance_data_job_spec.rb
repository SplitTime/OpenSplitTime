require "rails_helper"

RSpec.describe RecomputeEffortPerformanceDataJob do
  let(:event) { events(:hardrock_2015) }
  let(:effort) { efforts(:hardrock_2015_tuan_jacobs) }

  describe "#perform" do
    it "restores consistency for a perturbed effort" do
      bits = effort.overall_performance.to_s
      field = (bits[15...45].to_i(2) + 1).to_s(2).rjust(30, "0")
      effort.update_columns(overall_performance: bits[0...15] + field + bits[45..])
      expect(event.performance_data_stale?).to be(true)

      described_class.perform_now([event.id])

      expect(event.performance_data_stale?).to be(false)
      expect(effort.reload.overall_performance.to_s).to eq(bits)
    end
  end
end
