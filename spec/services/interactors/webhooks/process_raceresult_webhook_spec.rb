require "rails_helper"

RSpec.describe Interactors::Webhooks::ProcessRaceresultWebhook do
  include BitkeyDefinitions

  let(:event_group) { event_groups(:hardrock_2014) }

  let(:record) do
    {
      "Bib" => bib,
      "TimingPoint" => timing_point,
      "ID" => id,
      "Passing" => {
        "UTCTime" => utc_time,
        "DeviceID" => device_id
      }
    }
  end

  let(:bib) { "101" }
  let(:timing_point) { "Aid 1" }
  let(:id) { 12_345 }
  let(:utc_time) { "2014-07-11T10:45:00Z" }
  let(:device_id) { "device_1" }

  describe ".call" do
    let(:result) { described_class.call(event_group: event_group, record: record) }

    context "when given valid data" do
      before do
        allow(ProcessImportedRawTimesJob).to receive(:perform_later)
      end

      it "returns a successful response with a raw_time" do
        expect(result.errors).to be_empty
        expect(result.resources.size).to eq(1)
      end

      it "creates a RawTime record" do
        expect { result }.to change(RawTime, :count).by(1)
      end

      it "creates a RawTime with the correct attributes" do
        result
        raw_time = RawTime.last

        expect(raw_time.event_group).to eq(event_group)
        expect(raw_time.bib_number).to eq("101")
        expect(raw_time.split_name).to eq("Aid 1")
        expect(raw_time.entered_time).to eq("2014-07-11T10:45:00Z")
        expect(raw_time.bitkey).to eq(SubSplit::IN_BITKEY)
        expect(raw_time.source).to eq("raceresult-webhook-device_1")
      end

      it "enqueues a job to process the raw time" do
        result

        expect(ProcessImportedRawTimesJob).to have_received(:perform_later).with(event_group, [RawTime.last])
      end

      context "when DeviceID is missing" do
        let(:device_id) { nil }

        it "sets source to raceresult-webhook" do
          result
          expect(RawTime.last.source).to eq("raceresult-webhook")
        end
      end
    end

    context "when Bib is missing" do
      let(:bib) { nil }

      it "returns an error" do
        expect(result.errors).to be_present
        expect(result.resources).to be_empty
      end
    end

    context "when TimingPoint is missing" do
      let(:timing_point) { nil }

      it "returns an error" do
        expect(result.errors).to be_present
        expect(result.resources).to be_empty
      end
    end

    context "when Passing.UTCTime is missing" do
      let(:utc_time) { nil }

      it "returns an error" do
        expect(result.errors).to be_present
        expect(result.resources).to be_empty
      end
    end

    context "when ID is missing" do
      let(:id) { nil }

      it "returns an error" do
        expect(result.errors).to be_present
        expect(result.resources).to be_empty
      end
    end
  end
end
