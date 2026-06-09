require "rails_helper"

RSpec.describe GatingLocation, type: :model do
  subject(:gating_location) { described_class.new(event_group: event_group, name: name) }

  let(:event_group) { event_groups(:rufa_2017) }
  let(:name) { "Highway Gate" }

  describe "validations" do
    context "with an event group and a name" do
      it "is valid" do
        expect(gating_location).to be_valid
      end
    end

    context "without a name" do
      let(:name) { nil }

      it "is invalid" do
        expect(gating_location).not_to be_valid
        expect(gating_location.errors[:name]).to include("can't be blank")
      end
    end

    context "when the name is already taken within the event group" do
      let(:event_group) { event_groups(:sum) }
      let(:name) { "Bandera Gate" }

      it "is invalid" do
        expect(gating_location).not_to be_valid
        expect(gating_location.errors[:name]).to include("has already been taken")
      end
    end

    context "when the name is taken only in another event group" do
      let(:name) { "Bandera Gate" }

      it "is valid" do
        expect(gating_location).to be_valid
      end
    end
  end

  describe "#destroy" do
    it "destroys associated gating location events" do
      gating_location = gating_locations(:sum_bandera_gate)
      expect { gating_location.destroy }.to change(GatingLocationEvent, :count).by(-2)
    end
  end
end
