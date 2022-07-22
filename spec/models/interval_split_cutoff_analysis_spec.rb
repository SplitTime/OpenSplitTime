# frozen_string_literal: true

require "rails_helper"

RSpec.describe IntervalSplitCutoffAnalysis, type: :model do
  describe ".execute_query" do
    subject { described_class.execute_query(split: split, band_width: band_width) }
    let(:band_width) { 1.hour }

    before(:all) { EffortSegment.set_all }
    after(:all) { EffortSegment.delete_all }

    context "for a split close to the start" do
      let(:split) { splits(:hardrock_ccw_cunningham) }

      it "returns an array of IntervalSplitCutoffAnalysis objects" do
        expect(subject.size).to eq(3)
        expect(subject.map(&:start_seconds)).to eq([3600, 7200, 10800])
        expect(subject.map(&:end_seconds)).to eq([7200, 10800, 14400])
        expect(subject.map(&:total_count)).to eq([2, 20, 8])
        expect(subject.map(&:finished_count)).to eq([2, 18, 5])
      end
    end

    context "for a split extending over multiple days" do
      let(:split) { splits(:hardrock_ccw_telluride) }

      it "returns an array of IntervalSplitCutoffAnalysis objects reflecting multiple days" do
        expect(subject.size).to eq(19)

        subject_isca = subject[10]
        expect(subject_isca.start_seconds).to eq(90_000)
        expect(subject_isca.end_seconds).to eq(93_600)
        expect(subject_isca.total_count).to eq(4)
        expect(subject_isca.finished_count).to eq(4)
      end
    end

    context "when the query would return too many rows" do
      let(:split) { splits(:hardrock_ccw_telluride) }
      let(:band_width) { 1.minute }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end
end
