require "rails_helper"

RSpec.describe Interactors::ResetEffortPerformanceData do
  subject { described_class.new(event) }

  let(:event) { events(:sum_100k) }

  describe "#perform!" do
    context "when no efforts have stale performance data" do
      it "returns a successful response with no message" do
        response = subject.perform!

        expect(response).to be_successful
        expect(response.message).to be_nil
      end
    end

    context "when an effort is marked started but has no split times" do
      let(:stale_effort) { event.efforts.started.first }

      before do
        split_time_ids = SplitTime.where(effort_id: stale_effort.id).pluck(:id)
        RawTime.where(split_time_id: split_time_ids).update_all(split_time_id: nil)
        SplitTime.where(id: split_time_ids).delete_all
      end

      it "resets the effort performance data" do
        expect(stale_effort.started).to eq(true)

        subject.perform!
        stale_effort.reload

        expect(stale_effort.started).to eq(false)
        expect(stale_effort.final_split_time_id).to be_nil
      end

      it "returns a successful response with a descriptive message" do
        response = subject.perform!

        expect(response).to be_successful
        expect(response.message).to include("Reset performance data for 1 effort")
      end
    end
  end
end
