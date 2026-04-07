require "rails_helper"

RSpec.describe RawTimeData do
  subject { described_class.new(absolute_time_string: absolute_time_string, absolute_time_local_string: absolute_time_local_string, entered_time: entered_time, data_status_numeric: data_status_numeric, stopped_here: stopped_here, source: source, created_by: created_by) }

  let(:absolute_time_string) { nil }
  let(:absolute_time_local_string) { nil }
  let(:entered_time) { nil }
  let(:data_status_numeric) { nil }
  let(:stopped_here) { nil }
  let(:source) { nil }
  let(:created_by) { nil }

  it { expect(described_class.ancestors).to include(SourceTextable) }

  describe "#absolute_time" do
    let(:result) { subject.absolute_time }

    context "when absolute_time_string is present" do
      let(:absolute_time_string) { "2024-07-11 10:45:00 UTC" }

      it { expect(result).to eq(DateTime.parse("2024-07-11 10:45:00 UTC")) }
    end

    context "when absolute_time_string is nil" do
      it { expect(result).to be_nil }
    end
  end

  describe "#absolute_time_local" do
    let(:result) { subject.absolute_time_local }

    context "when absolute_time_local_string is present" do
      let(:absolute_time_local_string) { "2024-07-11 04:45:00" }

      it { expect(result).to eq(DateTime.parse("2024-07-11 04:45:00")) }
    end

    context "when absolute_time_local_string is nil" do
      it { expect(result).to be_nil }
    end
  end

  describe "#military_time" do
    let(:result) { subject.military_time }

    context "when absolute_time_local_string is present" do
      let(:absolute_time_local_string) { "2024-07-11 10:45:00" }

      it { expect(result).to eq("10:45:00") }
    end

    context "when absolute_time_local_string is blank" do
      let(:entered_time) { "10:45:00" }

      it { expect(result).to eq("10:45:00") }
    end
  end

  describe "#data_status" do
    let(:result) { subject.data_status }

    context "when data_status_numeric is a known value" do
      let(:data_status_numeric) { 2 }

      it { expect(result).to eq("good") }
    end

    context "when data_status_numeric is an unknown value" do
      let(:data_status_numeric) { 99 }

      it { expect(result).to be_nil }
    end
  end

  describe "#stopped_here?" do
    let(:result) { subject.stopped_here? }

    context "when stopped_here is true" do
      let(:stopped_here) { true }

      it { expect(result).to be true }
    end

    context "when stopped_here is false" do
      let(:stopped_here) { false }

      it { expect(result).to be false }
    end
  end
end
