require "rails_helper"

RSpec.describe BestEffortSegment do
  describe "#place" do
    # event_rank is a runtime select alias added by a ranking scope, so a plain record won't carry it.
    subject(:segment) { described_class.new.tap { |s| s.define_singleton_method(:event_rank) { 3 } } }

    it "returns the segment's event_rank, so the course-group CSV export can serialize `place`" do
      expect(segment.place).to eq(3)
    end

    it "is one of the configured CSV export attributes" do
      expect(BestEffortSegmentParameters.csv_export_attributes).to include("place")
    end
  end
end
