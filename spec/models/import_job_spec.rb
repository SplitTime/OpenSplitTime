# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImportJob, type: :model do
  subject { described_class.new(started_at: started_at, status: status) }
  let(:started_at) { nil }
  let(:status) { nil }

  describe "#elapsed_time" do
    let(:result) { subject.elapsed_time }

    before { travel_to ::Time.current }

    context "when started at is nil" do
      it { expect(result).to be_nil }
    end

    context "when started at is set" do
      let(:started_at) { 2.minutes.ago }
      it "returns elapsed time in seconds" do
        expect(result).to eq(120)
      end
    end
  end

  describe "#start!" do
    before { travel_to test_start_time }
    let(:test_start_time) { "2021-10-31 10:00:00".in_time_zone }
    context "when the import job has not been started" do
      it "sets start time as expected" do
        subject.start!
        expect(subject.started_at).to eq(test_start_time)
      end
    end

    context "when the import job has already been started" do
      let(:started_at) { 2.minutes.ago }
      it "overwrites the existing start time" do
        subject.start!
        expect(subject.started_at).to eq(test_start_time)
      end
    end
  end
end
