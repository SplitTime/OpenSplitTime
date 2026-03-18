require "rails_helper"

RSpec.describe AidStationDetail do
  let(:event) { events(:rufa_2017_24h) }
  let(:split) { event.ordered_splits.second }
  let(:params) { OpenStruct.new(sort: [], original_params: {}) }

  subject { AidStationDetail.new(event: event, parameterized_split_name: split.parameterized_base_name, params: params) }

  describe "#initialize" do
    context "with an event" do
      it "initializes" do
        expect { subject }.not_to raise_error
      end
    end

    context "if no event is given" do
      it "raises an ArgumentError" do
        expect { AidStationDetail.new(event: nil) }.to raise_error(ArgumentError, /must include event/)
      end
    end
  end

  describe "#display_style" do
    context "when params include a display_style" do
      let(:params) { OpenStruct.new(display_style: "stopped_here", original_params: {}) }

      it "returns the parameterized display style as a symbol" do
        expect(subject.display_style).to eq(:stopped_here)
      end
    end

    context "when params do not include a display_style" do
      let(:params) { OpenStruct.new(display_style: nil, original_params: {}) }

      it "returns the default display style" do
        expect(subject.display_style).to eq(:expected)
      end
    end
  end

  describe "#split" do
    context "when parameterized_split_name matches a split" do
      it "returns the matching split" do
        expect(subject.split).to eq(split)
      end
    end

    context "when parameterized_split_name does not match any split" do
      subject { AidStationDetail.new(event: event, parameterized_split_name: "nonexistent", params: params) }

      it "returns the last ordered split" do
        expect(subject.split).to eq(event.ordered_splits.last)
      end
    end
  end

  describe "#effort_data" do
    it "returns an array" do
      expect(subject.effort_data).to be_an(Array)
    end
  end

  describe "delegated methods" do
    it "delegates course to event" do
      expect(subject.course).to eq(event.course)
    end

    it "delegates organization to event" do
      expect(subject.organization).to eq(event.organization)
    end
  end
end
