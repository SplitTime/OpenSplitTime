require "rails_helper"

RSpec.describe AidStationsDisplay do
  let(:event) { events(:rufa_2017_24h) }

  subject { AidStationsDisplay.new(event: event) }

  describe "#initialize" do
    context "with an event" do
      it "initializes" do
        expect { subject }.not_to raise_error
      end
    end

    context "if no event is given" do
      it "raises an ArgumentError" do
        expect { AidStationsDisplay.new(event: nil) }.to raise_error(ArgumentError, /must include event/)
      end
    end
  end

  describe "#aid_station_rows" do
    it "returns an array of AidStationRow objects" do
      expect(subject.aid_station_rows).to all(be_a(AidStationRow))
    end

    it "returns one row per aid station" do
      expect(subject.aid_station_rows.size).to eq(event.aid_stations.count)
    end
  end

  describe "#start_time" do
    it "returns the event scheduled start time local" do
      expect(subject.start_time).to eq(event.scheduled_start_time_local)
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
