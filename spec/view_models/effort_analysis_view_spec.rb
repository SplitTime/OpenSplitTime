require "rails_helper"

RSpec.describe EffortAnalysisView do
  describe "#sorted_analysis_rows" do
    it "treats non-float numeric values as sortable" do
      view = described_class.allocate

      row_int = instance_double("EffortAnalysisRow", segment_over_under_percent: 2)
      row_float = instance_double("EffortAnalysisRow", segment_over_under_percent: 1.5)

      allow(view).to receive(:analysis_rows).and_return([row_int, row_float])

      expect(view.send(:sorted_analysis_rows)).to eq([row_float, row_int])
    end
  end
end
