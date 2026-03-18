require "rails_helper"

RSpec.describe AidStationDetail do
  subject { described_class.new(event: event, parameterized_split_name: parameterized_split_name, params: params) }

  let(:event) { events(:rufa_2017_24h) }
  let(:parameterized_split_name) { split.parameterized_base_name }
  let(:split) { event.ordered_splits.second }
  let(:params) { PreparedParams.new(ActionController::Parameters.new(param_options), []) }
  let(:param_options) { {} }

  describe "#initialize" do
    context "with an event" do
      it "initializes" do
        expect { subject }.not_to raise_error
      end
    end

    context "when no event is given" do
      it "raises an ArgumentError" do
        expect { described_class.new(event: nil) }.to raise_error(ArgumentError, /must include event/)
      end
    end
  end

  describe "#display_style" do
    let(:result) { subject.display_style }

    context "when params do not include a display_style" do
      it "returns the default display style" do
        expect(result).to eq(:expected)
      end
    end

    context "when params include a display_style" do
      let(:param_options) { { display_style: "stopped_here" } }

      it "returns the parameterized display style as a symbol" do
        expect(result).to eq(:stopped_here)
      end
    end
  end

  describe "#split" do
    let(:result) { subject.split }

    context "when parameterized_split_name matches a split" do
      it "returns the matching split" do
        expect(result).to eq(split)
      end
    end

    context "when parameterized_split_name does not match any split" do
      let(:parameterized_split_name) { "nonexistent" }

      it "returns the last ordered split" do
        expect(result).to eq(event.ordered_splits.last)
      end
    end
  end

  describe "#effort_data" do
    let(:result) { subject.effort_data }

    it "returns an array" do
      expect(result).to be_an(Array)
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
