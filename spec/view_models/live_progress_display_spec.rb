require "rails_helper"

RSpec.describe LiveProgressDisplay do
  subject(:display) { described_class.new(event: event, past_due_threshold: past_due_threshold) }

  let(:event) { events(:hardrock_2015) }
  let(:past_due_threshold) { 30 }

  describe "#initialize" do
    context "when initialized with an event" do
      it { expect { subject }.not_to raise_error }
    end

    context "when initialized without an event" do
      let(:event) { nil }

      it { expect { subject }.to raise_error ArgumentError, /must include event/ }
    end
  end

  describe "#past_due_threshold" do
    context "when a threshold is provided" do
      let(:past_due_threshold) { 45 }

      it "returns the provided threshold" do
        expect(subject.past_due_threshold).to eq(45)
      end
    end

    context "when no threshold is provided" do
      let(:past_due_threshold) { nil }

      it "defaults to 30" do
        expect(subject.past_due_threshold).to eq(30)
      end
    end

    context "when threshold is a string" do
      let(:past_due_threshold) { "60" }

      it "converts to integer" do
        expect(subject.past_due_threshold).to eq(60)
      end
    end
  end

  describe "#past_due_progress_rows" do
    it "returns an array" do
      expect(subject.past_due_progress_rows).to be_a(Array)
    end

    context "when an in-progress effort has no due_next_time_point" do
      let(:past_due_threshold) { 0 }

      it "does not raise an error" do
        progress_rows = subject.send(:progress_rows)
        progress_rows.each do |row|
          allow(row).to receive(:due_next_time_point).and_return(nil)
        end
        expect { subject.past_due_progress_rows }.not_to raise_error
      end
    end
  end

  describe "#efforts_past_due_count" do
    it "returns a non-negative integer" do
      expect(subject.efforts_past_due_count).to be >= 0
    end
  end
end
