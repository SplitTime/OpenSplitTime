require "rails_helper"

RSpec.describe EffortWithTimesRowPresenter do
  subject { described_class.new(effort) }

  let(:effort) { build_stubbed(:effort) }

  describe "#initialize" do
    context "when given an effort" do
      it "initializes" do
        expect { subject }.not_to raise_error
      end
    end

    context "without an effort argument" do
      let(:effort) { nil }

      it "raises an error" do
        expect { subject }.to raise_error(ArgumentError, /must include effort/)
      end
    end
  end

  describe "#effort_times_row_id" do
    it "returns the effort id" do
      expect(subject.effort_times_row_id).to eq(effort.id)
    end
  end
end
