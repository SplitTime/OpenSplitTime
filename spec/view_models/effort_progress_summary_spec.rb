require "rails_helper"

RSpec.describe EffortProgressSummary do
  subject { described_class.new(effort: effort, event_framework: event_framework) }

  let(:event) { events(:rufa_2017_24h) }
  let(:event_framework) { LiveProgressDisplay.new(event: event) }
  let(:effort) { event.efforts.ranking_subquery.finish_info_subquery.first }

  describe "#initialize" do
    context "with an effort and event_framework" do
      it "initializes" do
        expect { subject }.not_to raise_error
      end
    end

    context "when no effort is given" do
      let(:effort) { nil }
      it { expect { subject }.to raise_error(/must include effort/) }
    end

    context "when no event_framework is given" do
      let(:event_framework) { nil }
      it { expect { subject }.to raise_error(/must include event_framework/) }
    end
  end

  describe "past due methods" do
    let(:summary) { described_class.new(effort: effort, event_framework: event_framework) }

    describe "#minutes_past_due" do
      let(:result) { summary.minutes_past_due }

      context "when next_absolute_time is present" do
        before { allow(summary).to receive(:next_absolute_time).and_return(15.minutes.ago) }

        it "returns the number of minutes between now and the next expected time" do
          expect(result).to eq(15)
        end
      end

      context "when next_absolute_time is nil" do
        before { allow(summary).to receive(:next_absolute_time).and_return(nil) }

        it "returns nil" do
          expect(result).to be_nil
        end
      end
    end

    describe "#seconds_past_due" do
      let(:result) { summary.seconds_past_due }

      context "when minutes_past_due is present" do
        before { allow(summary).to receive(:minutes_past_due).and_return(10) }

        it "returns minutes_past_due converted to seconds" do
          expect(result).to eq(600)
        end
      end

      context "when minutes_past_due is nil" do
        before { allow(summary).to receive(:minutes_past_due).and_return(nil) }

        it "returns nil" do
          expect(result).to be_nil
        end
      end
    end

    describe "#past_due?" do
      let(:result) { summary.past_due? }

      context "when minutes_past_due exceeds the threshold" do
        before { allow(summary).to receive(:minutes_past_due).and_return(45) }

        it "returns true" do
          expect(result).to eq(true)
        end
      end

      context "when minutes_past_due is below the threshold" do
        before { allow(summary).to receive(:minutes_past_due).and_return(5) }

        it "returns false" do
          expect(result).to eq(false)
        end
      end

      context "when minutes_past_due is nil" do
        before { allow(summary).to receive(:minutes_past_due).and_return(nil) }

        it "returns false" do
          expect(result).to be false
        end
      end
    end
  end

  describe "when effort has reached the finish" do
    let(:effort) { create(:effort) }
    let(:event_framework) { LiveEventFramework.new(event: effort.event) }
    let(:summary) { described_class.new(effort: effort, event_framework: event_framework) }

    before do
      # Simulate effort at finish with no more time points
      allow(summary).to receive(:due_next_time_point).and_return(nil)
    end

    it "does not raise errors when calculating past_due?" do
      expect { summary.past_due? }.not_to raise_error
    end

    it "returns false for past_due?" do
      expect(summary.past_due?).to be false
    end

    it "returns nil for minutes_past_due" do
      expect(summary.minutes_past_due).to be_nil
    end
  end
end
