require "rails_helper"

RSpec.describe EffortProgressSummary do
  let(:event) { events(:rufa_2017_24h) }
  let(:event_framework) { LiveProgressDisplay.new(event: event) }
  let(:effort) { event.efforts.ranking_subquery.finish_info_subquery.first }

  subject { EffortProgressSummary.new(effort: effort, event_framework: event_framework) }

  describe "#initialize" do
    context "with an effort and event_framework" do
      it "initializes" do
        expect { subject }.not_to raise_error
      end
    end

    context "if no effort is given" do
      let(:effort) { nil }

      it "raises an ArgumentError" do
        expect { subject }.to raise_error(/must include effort/)
      end
    end

    context "if no event_framework is given" do
      let(:event_framework) { nil }

      it "raises an ArgumentError" do
        expect { EffortProgressSummary.new(effort: effort, event_framework: nil) }.to raise_error(/must include event_framework/)
      end
    end
  end

  describe "#minutes_past_due" do
    context "when next_absolute_time is present" do
      it "returns the number of minutes between now and the next expected time" do
        allow(subject).to receive(:next_absolute_time).and_return(15.minutes.ago)
        expect(subject.minutes_past_due).to eq(15)
      end
    end

    context "when next_absolute_time is nil" do
      it "returns nil" do
        allow(subject).to receive(:next_absolute_time).and_return(nil)
        expect(subject.minutes_past_due).to be_nil
      end
    end
  end

  describe "#seconds_past_due" do
    it "returns minutes_past_due converted to seconds" do
      allow(subject).to receive(:minutes_past_due).and_return(10)
      expect(subject.seconds_past_due).to eq(600)
    end
  end

  describe "#past_due?" do
    context "when minutes_past_due exceeds the threshold" do
      it "returns true" do
        allow(subject).to receive(:minutes_past_due).and_return(45)
        expect(subject.past_due?).to eq(true)
      end
    end

    context "when minutes_past_due is below the threshold" do
      it "returns false" do
        allow(subject).to receive(:minutes_past_due).and_return(5)
        expect(subject.past_due?).to eq(false)
      end
    end

    context "when minutes_past_due is nil" do
      it "returns nil" do
        allow(subject).to receive(:minutes_past_due).and_return(nil)
        expect(subject.past_due?).to be_nil
      end
    end
  end
end
