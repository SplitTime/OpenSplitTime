require "rails_helper"

RSpec.describe GatingLocationEvent, type: :model do
  subject(:gating_location_event) do
    described_class.new(
      gating_location: gating_location,
      event: event,
      gating_aid_station: gating_aid_station,
      target_aid_station: target_aid_station,
    )
  end

  let(:gating_location) { GatingLocation.new(event_group: event_groups(:sum), name: "Engineer Gate") }
  let(:event) { events(:sum_100k) }
  let(:gating_aid_station) { aid_stations(:aid_station_0017) } # sum_100k molas_pass_aid1
  let(:target_aid_station) { aid_stations(:aid_station_0019) } # sum_100k cascade_creek_rd_aid3

  describe "validations" do
    context "with an event and aid stations in proper order" do
      it "is valid" do
        expect(gating_location_event).to be_valid
      end
    end

    context "when the event is already configured for the gating location" do
      let(:gating_location) { gating_locations(:sum_bandera_gate) }

      it "is invalid" do
        expect(gating_location_event).not_to be_valid
        expect(gating_location_event.errors[:event_id])
          .to include("only one configuration permitted per event within a gating location")
      end
    end

    context "when the gating aid station belongs to another event" do
      let(:gating_aid_station) { aid_stations(:aid_station_0043) } # sum_55k molas_pass_aid1

      it "is invalid" do
        expect(gating_location_event).not_to be_valid
        expect(gating_location_event.errors[:gating_aid_station_id]).to include("must be an aid station of the same event")
      end
    end

    context "when the target aid station belongs to another event" do
      let(:target_aid_station) { aid_stations(:aid_station_0039) } # sum_55k bandera_mine_aid5

      it "is invalid" do
        expect(gating_location_event).not_to be_valid
        expect(gating_location_event.errors[:target_aid_station_id]).to include("must be an aid station of the same event")
      end
    end

    context "when the event does not belong to the gating location's event group" do
      let(:event) { events(:hardrock_2015) }
      let(:gating_aid_station) { aid_stations(:aid_station_0002) } # hardrock_2015 start
      let(:target_aid_station) { aid_stations(:aid_station_0006) } # hardrock_2015 finish

      it "is invalid" do
        expect(gating_location_event).not_to be_valid
        expect(gating_location_event.errors[:event_id])
          .to include("must belong to the same event group as the gating location")
      end
    end

    context "when the gating and target aid stations are the same" do
      let(:target_aid_station) { gating_aid_station }

      it "is invalid" do
        expect(gating_location_event).not_to be_valid
        expect(gating_location_event.errors[:target_aid_station_id])
          .to include("must be farther along the course than the gating aid station")
      end
    end

    context "when the gating aid station is beyond the target aid station" do
      let(:gating_aid_station) { aid_stations(:aid_station_0020) } # sum_100k bandera_mine_aid5
      let(:target_aid_station) { aid_stations(:aid_station_0021) } # sum_100k engineer_mtn_th_aid4

      it "is invalid" do
        expect(gating_location_event).not_to be_valid
        expect(gating_location_event.errors[:target_aid_station_id])
          .to include("must be farther along the course than the gating aid station")
      end
    end

    describe "default_travel_buffer" do
      it "defaults to 30" do
        expect(gating_location_event.default_travel_buffer).to eq(30)
      end

      it "is valid at the bounds" do
        gating_location_event.default_travel_buffer = 0
        expect(gating_location_event).to be_valid

        gating_location_event.default_travel_buffer = 1200
        expect(gating_location_event).to be_valid
      end

      it "is invalid below 0" do
        gating_location_event.default_travel_buffer = -1
        expect(gating_location_event).not_to be_valid
        expect(gating_location_event.errors[:default_travel_buffer]).to be_present
      end

      it "is invalid above 1200" do
        gating_location_event.default_travel_buffer = 1201
        expect(gating_location_event).not_to be_valid
        expect(gating_location_event.errors[:default_travel_buffer]).to be_present
      end

      it "is invalid when non-integer" do
        gating_location_event.default_travel_buffer = 15.5
        expect(gating_location_event).not_to be_valid
        expect(gating_location_event.errors[:default_travel_buffer]).to be_present
      end
    end
  end

  describe "fixtures" do
    it "are valid" do
      expect(gating_location_events(:sum_bandera_gate_100k)).to be_valid
      expect(gating_location_events(:sum_bandera_gate_55k)).to be_valid
    end
  end

  describe "cleanup when an aid station is destroyed" do
    context "when the aid station is a gating aid station" do
      it "destroys the dependent gating location event" do
        expect { aid_stations(:aid_station_0021).destroy }.to change(described_class, :count).by(-1)
      end
    end

    context "when the aid station is a target aid station" do
      it "destroys the dependent gating location event" do
        expect { aid_stations(:aid_station_0020).destroy }.to change(described_class, :count).by(-1)
      end
    end
  end
end
