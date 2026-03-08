require "rails_helper"

RSpec.describe EffortAnalysisView do
  describe "#sorted_analysis_rows" do
    it "does not raise when segment_over_under_percent includes NaN" do
      view = described_class.allocate

      row_ok_low = instance_double("EffortAnalysisRow", segment_over_under_percent: -5.0)
      row_nan = instance_double("EffortAnalysisRow", segment_over_under_percent: Float::NAN)
      row_ok_high = instance_double("EffortAnalysisRow", segment_over_under_percent: 10.0)
      row_nil = instance_double("EffortAnalysisRow", segment_over_under_percent: nil)

      allow(view).to receive(:analysis_rows).and_return([row_ok_high, row_nan, row_ok_low, row_nil])

      expect { view.send(:sorted_analysis_rows) }.not_to raise_error
      expect(view.send(:sorted_analysis_rows)).to eq([row_ok_low, row_ok_high])
    end

    it "treats non-float numeric values as sortable" do
      view = described_class.allocate

      row_int = instance_double("EffortAnalysisRow", segment_over_under_percent: 2)
      row_float = instance_double("EffortAnalysisRow", segment_over_under_percent: 1.5)

      allow(view).to receive(:analysis_rows).and_return([row_int, row_float])

      expect(view.send(:sorted_analysis_rows)).to eq([row_float, row_int])
    end
  end
end
