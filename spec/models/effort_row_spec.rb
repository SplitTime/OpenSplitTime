require "rails_helper"

RSpec.describe EffortRow, type: :model do
  subject { described_class.new(test_effort) }

  let(:test_effort) { build_stubbed(:effort, state_code: "CA", country_code: country_code, age: 30) }
  let(:test_person) { build_stubbed(:person) }
  let(:country_code) { "US" }

  before do
    allow(test_effort).to receive(:finished?).and_return(false)
    allow(test_effort).to receive(:dropped?).and_return(false)
    allow(test_effort).to receive(:in_progress?).and_return(false)
  end

  describe "#initializate" do
    it "instantiates an EffortRow if provided an effort" do
      expect { EffortRow.new(test_effort) }.not_to raise_error
    end
  end

  describe "effort_attributes" do
    it "returns delegated effort attributes" do
      expect(subject.first_name).to eq(test_effort.first_name)
      expect(subject.last_name).to eq(test_effort.last_name)
      expect(subject.gender).to eq(test_effort.gender)
      expect(subject.state_code).to eq(test_effort.state_code)
    end

    it "returns attributes from PersonalInfo module" do
      expect(subject.full_name).to eq(test_effort.full_name)
      expect(subject.bio_historic).to eq(test_effort.bio_historic)
      expect(subject.state_and_country).to eq(test_effort.state_and_country)
    end
  end

  describe "#country_code_alpha_3" do
    let(:result) { subject.country_code_alpha_3 }

    context "when country code is nil" do
      let(:country_code) { nil }
      it "returns nil" do
        expect(result).to be_nil
      end
    end

    context "when country code is valid" do
      let(:country_code) { "US" }
      it "returns the three-letter equivalent code" do
        expect(result).to eq("USA")
      end
    end

    context "when country code is invalid" do
      let(:country_code) { "XX" }
      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end

  describe "#country_code_ioc" do
    let(:result) { subject.country_code_ioc }

    context "when country code is nil" do
      let(:country_code) { nil }
      it "returns nil" do
        expect(result).to be_nil
      end
    end

    context "when country code is valid" do
      let(:country_code) { "US" }
      it "returns the three-letter ioc code" do
        expect(result).to eq("USA")
      end
    end

    context "when ioc code is different from iso code" do
      let(:country_code) { "DE" }
      it "returns the three-letter ioc code" do
        expect(result).to eq("GER")
      end
    end

    context "when country code is invalid" do
      let(:country_code) { "XX" }
      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end

  describe "#effort_status" do
    context "when the run is neither finished nor dropped nor in progress" do
      it "returns 'Not Started'" do
        expect(subject.effort_status).to eq("Not Started")
      end
    end

    context "when the run is finished" do
      before { allow(test_effort).to receive(:finished?).and_return(true) }
      it "returns 'Finished'" do
        expect(subject.effort_status).to eq("Finished")
      end
    end

    context "when the run is dropped" do
      before { allow(test_effort).to receive(:dropped?).and_return(true) }
      it "returns 'Dropped'" do
        expect(subject.effort_status).to eq("Dropped")
      end
    end

    context "when the run is in progress" do
      before { allow(test_effort).to receive(:in_progress?).and_return(true) }
      it "returns 'In Progress'" do
        expect(subject.effort_status).to eq("In Progress")
      end
    end
  end

  describe "#ultrasignup_finish_status" do
    let(:result) { subject.ultrasignup_finish_status }

    context "when the run is neither finished nor dropped nor in progress" do
      it "returns 3" do
        expect(result).to eq(3)
      end
    end

    context "when the run is finished" do
      before { allow(test_effort).to receive(:finished?).and_return(true) }
      it "returns 1" do
        expect(result).to eq(1)
      end
    end

    context "when the run is dropped" do
      before { allow(test_effort).to receive(:dropped?).and_return(true) }
      it "returns 2" do
        expect(result).to eq(2)
      end
    end

    context "when a run is in progress" do
      before { allow(test_effort).to receive(:in_progress?).and_return(true) }
      it "returns a warning message" do
        expect(result).to match(/is in progress/)
      end
    end
  end
end
