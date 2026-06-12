require "rails_helper"

RSpec.describe CrewPassage, type: :model do
  subject(:crew_passage) do
    described_class.new(gating_location: gating_location, effort: effort, passed_at: passed_at)
  end

  let(:gating_location) { gating_locations(:sum_bandera_gate) }
  let(:effort) { efforts(:sum_100k_drop_anvil) }
  let(:passed_at) { "2017-09-23 21:00:00" }

  describe "validations" do
    context "with a gating location, effort, and passed_at time" do
      it "is valid" do
        expect(crew_passage).to be_valid
      end
    end

    context "without a passed_at time" do
      let(:passed_at) { nil }

      it "is invalid" do
        expect(crew_passage).not_to be_valid
        expect(crew_passage.errors[:passed_at]).to include("can't be blank")
      end
    end

    context "when a passage already exists for the effort at the gating location" do
      let(:effort) { efforts(:sum_100k_progress_cascade) }

      it "is invalid" do
        expect(crew_passage).not_to be_valid
        expect(crew_passage.errors[:effort_id]).to include("only one crew passage permitted per gating location")
      end
    end

    context "when the effort's event is not gated at the location" do
      let(:effort) { efforts(:hardrock_2015_bruno_fadel) }

      it "is invalid" do
        expect(crew_passage).not_to be_valid
        expect(crew_passage.errors[:effort_id]).to include("must belong to an event gated at this location")
      end
    end
  end

  describe "#destroy cascades" do
    it "is destroyed with its gating location" do
      expect { gating_locations(:sum_bandera_gate).destroy }.to change(described_class, :count).by(-1)
    end

    it "is destroyed with its effort" do
      expect { efforts(:sum_100k_progress_cascade).destroy }.to change(described_class, :count).by(-1)
    end
  end
end
