require 'rails_helper'

RSpec.describe Interactors::Webhooks::ProcessRaceresultWebhook do
  let(:event_group) { create(:event_group) }
  let(:raw_json) do
    {
      "Bib" => "123",
      "UTCTime" => "2024-03-01T10:30:45Z",
      "Passing" => { "DeviceID" => "device_01" },
      "TimingPoint" => "start",
      "ID" => "pass_001"
    }.to_json
  end
  let(:raw) { "#{raw_json};#{event_group.name}" }

  describe ".call" do
    it "creates and submits a raw time" do
      allow(RowifyRawTimes).to receive(:build).and_return([])
      allow(Interactors::SubmitRawTimeRows).to receive(:perform!)

      result = described_class.call(raw)

      expect(result).to be_a(RawTime)
      expect(result.bib_number).to eq("123")
      expect(result.source).to eq("raceresult_webhook")
    end
  end

  describe "#initialize" do
    it "stores the raw data" do
      interactor = described_class.new(raw)
      expect(interactor.send(:raw)).to eq(raw)
    end
  end

  describe "#parse_raw" do
    subject { described_class.new(raw) }

    it "parses JSON and extracts event_group_name" do
      subject.send(:parse_raw)

      raw_attrs = subject.send(:raw_attributes)
      eg_name = subject.send(:event_group_name)

      expect(raw_attrs).to include("Bib" => "123")
      expect(raw_attrs).to include("UTCTime" => "2024-03-01T10:30:45Z")
      expect(eg_name).to eq(event_group.name)
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

      expect(processed[:bib]).to eq("123")
      expect(processed[:utc_time]).to eq("2024-03-01T10:30:45Z")
      expect(processed[:device_id]).to eq("device_01")
      expect(processed[:timing_point]).to eq("start")
      expect(processed[:id]).to eq("pass_001")
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
      expect(raw_time.bib_number).to eq("123")
      expect(raw_time.split_name).to eq("start")
      expect(raw_time.entered_time).to eq("2024-03-01T10:30:45Z")
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
