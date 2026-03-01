require 'rails_helper'

RSpec.describe Interactors::Webhooks::ProcessRaceresultWebhook do
  let(:event_group) { create(:event_group) }
  let(:raw_json) do
    {
      "ID" => 162,
      "PID" => 3,
      "TimingPoint" => "Start",
      "Result" => -10,
      "Time" => 49_602.611,
      "Invalid" => false,
      "Bib" => 69,
      "Passing" => {
        "Transponder" => "69",
        "Position" => {
          "Latitude" => 39.941129,
          "Longitude" => -104.934041,
          "Altitude" => 0,
          "Flag" => "S"
        },
        "Hits" => 2,
        "RSSI" => -77,
        "Battery" => 0,
        "Temperature" => 0,
        "WUC" => 0,
        "LoopID" => 0,
        "Channel" => 0,
        "InternalData" => "2151f7",
        "StatusFlags" => 0,
        "DeviceID" => "D-55570",
        "DeviceName" => "D-55570",
        "OrderID" => 210084,
        "Port" => 2,
        "IsMarker" => false,
        "FileNo" => 32,
        "PassingNo" => 1,
        "Customer" => 99963,
        "Received" => "2026-03-01T20:46:43.77Z",
        "UTCTime" => "2026-03-01T13:46:42.611-06:00"
      }
    }.to_json
  end
  let(:raw) { "#{raw_json};#{event_group.name}" }

  describe ".call" do
    it "creates and submits a raw time" do
      allow(RowifyRawTimes).to receive(:build).and_return([])
      allow(Interactors::SubmitRawTimeRows).to receive(:perform!)

      result = described_class.call(raw)

      expect(result).to be_a(RawTime)
      expect(result.bib_number).to eq("69")
      expect(result.source).to eq("raceresult_webhook")
    end

    it "raises error when raw data is blank" do
      expect do
        described_class.call("")
      end.to raise_error(ArgumentError, "Raw data cannot be blank")
    end
  end

  describe "#parse_raw" do
    subject { described_class.new(raw) }

    it "parses JSON and extracts event_group_name" do
      subject.send(:parse_raw)

      raw_attrs = subject.send(:raw_attributes)
      eg_name = subject.send(:event_group_name)

      expect(raw_attrs).to include("Bib" => 69)
      expect(raw_attrs["Passing"]["UTCTime"]).to eq("2026-03-01T13:46:42.611-06:00")
      expect(eg_name).to eq(event_group.name)
    end

    it "raises error when format is invalid" do
      invalid_raw = described_class.new(raw_json)

      expect do
        invalid_raw.send(:parse_raw)
      end.to raise_error(ArgumentError, "Invalid format: expected JSON;EVENT_GROUP_NAME")
    end
  end

  describe "#find_event_group" do
    subject { described_class.new(raw) }

    it "finds the event group by name" do
      subject.send(:parse_raw)
      subject.send(:find_event_group)

      expect(subject.send(:event_group)).to eq(event_group)
    end

    it "raises error when event_group is not found" do
      subject = described_class.new("#{raw_json};nonexistent_group")
      subject.send(:parse_raw)

      expect do
        subject.send(:find_event_group)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "#process_data" do
    subject { described_class.new(raw) }

    it "maps raw attributes to processed attributes" do
      subject.send(:parse_raw)
      subject.send(:process_data)

      processed = subject.send(:processed_attributes)

      expect(processed[:bib]).to eq(69)
      expect(processed[:utc_time]).to eq("2026-03-01T13:46:42.611-06:00")
      expect(processed[:device_id]).to eq("D-55570")
      expect(processed[:timing_point]).to eq("Start")
      expect(processed[:id]).to eq(162)
    end

    it "raises error when Bib is missing" do
      json_without_bib = raw_json.gsub('"Bib":69', '"Bib":null')
      subject = described_class.new("#{json_without_bib};#{event_group.name}")
      subject.send(:parse_raw)

      expect do
        subject.send(:process_data)
      end.to raise_error(ArgumentError, "Missing required field: Bib")
    end

    it "raises error when TimingPoint is missing" do
      json_without_timing = raw_json.gsub('"TimingPoint":"Start"', '"TimingPoint":null')
      subject = described_class.new("#{json_without_timing};#{event_group.name}")
      subject.send(:parse_raw)

      expect do
        subject.send(:process_data)
      end.to raise_error(ArgumentError, "Missing required field: TimingPoint")
    end
  end

  describe "#build_raw_time" do
    subject { described_class.new(raw) }

    it "creates a RawTime object with correct attributes" do
      subject.send(:parse_raw)
      subject.send(:find_event_group)
      subject.send(:process_data)
      subject.send(:build_raw_time)

      raw_time = subject.send(:raw_time)

      expect(raw_time).to be_a(RawTime)
      expect(raw_time.event_group).to eq(event_group)
      expect(raw_time.bib_number).to eq("69")
      expect(raw_time.split_name).to eq("Start")
      expect(raw_time.entered_time).to eq("2026-03-01T13:46:42.611-06:00")
      expect(raw_time.bitkey).to eq(SubSplit::IN_BITKEY)
      expect(raw_time.source).to eq("raceresult_webhook")
      expect(raw_time.created_by).to be_nil
    end
  end

  describe "#save_raw_time" do
    subject { described_class.new(raw) }

    it "saves the raw time to the database" do
      subject.send(:parse_raw)
      subject.send(:find_event_group)
      subject.send(:process_data)
      subject.send(:build_raw_time)
      subject.send(:save_raw_time)

      raw_time = subject.send(:raw_time)

      expect(raw_time).to be_persisted
    end
  end

  describe "#submit_raw_time" do
    subject { described_class.new(raw) }

    it "submits the raw time rows" do
      subject.send(:parse_raw)
      subject.send(:find_event_group)
      subject.send(:process_data)
      subject.send(:build_raw_time)
      subject.send(:save_raw_time)

      expect(RowifyRawTimes).to receive(:build).with(
        event_group: event_group,
        raw_times: [subject.send(:raw_time)]
      ).and_return([])

      expect(Interactors::SubmitRawTimeRows).to receive(:perform!).with(
        raw_time_rows: [],
        event_group: event_group,
        force_submit: false,
        mark_as_reviewed: false,
        current_user_id: nil
      )

      subject.send(:submit_raw_time)
    end
  end
end