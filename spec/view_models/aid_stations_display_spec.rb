require "rails_helper"

RSpec.describe AidStationsDisplay do
  subject { described_class.new(event: event) }

  let(:event) { events(:rufa_2017_24h) }

  describe "#initialize" do
    context "with an event" do
      it "initializes" do
        expect { subject }.not_to raise_error
      end
    end

    context "when no event is given" do
      let(:event) { nil }
      it "raises an ArgumentError" do
        expect { subject }.to raise_error(ArgumentError, /must include event/)
      end
    end
  end

  describe "#aid_station_rows" do
    let(:result) { subject.aid_station_rows }

    it "returns an array of AidStationRow objects" do
      expect(result).to all(be_a(AidStationRow))
    end

    it "returns one row per aid station" do
      expect(result.count).to eq(event.aid_stations.count)
    end
  end

  describe "#start_time" do
    let(:result) { subject.start_time }

    it "returns the event scheduled start time local" do
      expect(result).to eq(event.scheduled_start_time_local)
    end
  end

  describe "delegated methods" do
    it "delegates course to event" do
      expect(subject.course).to eq(event.course)
    end

    it "delegates organization to event" do
      expect(subject.organization).to eq(event.organization)
    end

    it "delegates home_time_zone to event" do
      expect(subject.home_time_zone).to eq(event.home_time_zone)
    end
  end
end
