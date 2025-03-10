require "support/bitkey_definitions"

RSpec.shared_examples_for "time_recordable" do
  include BitkeyDefinitions

  let(:model) { described_class }
  let(:model_name) { model.name.underscore.to_sym }

  describe "#matched?" do
    context "when no split_time_id is present" do
      it "returns false" do
        resource = build_stubbed(model_name, split_time_id: nil)
        expect(resource.matched?).to eq(false)
      end
    end

    context "when a split_time_id is present" do
      it "returns true" do
        resource = build_stubbed(model_name, split_time_id: 1)
        expect(resource.matched?).to eq(true)
      end
    end
  end

  describe "#unmatched?" do
    context "when no split_time_id is present" do
      it "returns true" do
        resource = build_stubbed(model_name, split_time_id: nil)
        expect(resource.unmatched?).to eq(true)
      end
    end

    context "when a split_time_id is present" do
      it "returns false" do
        resource = build_stubbed(model_name, split_time_id: 1)
        expect(resource.unmatched?).to eq(false)
      end
    end
  end

  describe "#military_time" do
    let(:result) { resource.military_time(zone) }
    let(:zone) { nil }

    context "when absolute_time exists and a zone string argument is passed" do
      let(:resource) { build_stubbed(model_name, absolute_time: "2017-07-31 09:30:45 -0000", entered_time: "0123") }
      let(:zone) { "Eastern Time (US & Canada)" }

      it "returns the time component in hh:mm:ss format in the specified time zone" do
        expect(result).to eq("05:30:45")
      end
    end

    context "when absolute_time exists and a TimeZone object argument is passed" do
      let(:resource) { build_stubbed(model_name, absolute_time: "2017-07-31 09:30:45 -0000", entered_time: "0123") }
      let(:zone) { ActiveSupport::TimeZone["Eastern Time (US & Canada)"] }

      it "returns the time component in hh:mm:ss format in the specified time zone" do
        expect(result).to eq("05:30:45")
      end
    end

    context "when absolute_time exists, zone is not passed as an argument, and zone does not exist for the including class object" do
      let(:resource) { build_stubbed(model_name, absolute_time: "2017-07-31 09:30:45 -0000", entered_time: "01:23") }

      before { allow(resource).to receive(:home_time_zone).and_return(nil) }

      it "returns the entered_time in hh:mm:ss format" do
        expect(result).to eq("01:23:00")
      end
    end

    context "when absolute_time exists, zone is not passed as an argument, and zone exists for the including class object" do
      let(:resource) { build_stubbed(model_name, absolute_time: "2017-07-31 09:30:45 -0000", entered_time: "01:23") }

      before { allow(resource).to receive(:home_time_zone).and_return("Eastern Time (US & Canada)") }

      it "returns the time component in hh:mm:ss format in the specified time zone" do
        expect(result).to eq("05:30:45")
      end
    end

    context "when no absolute_time exists" do
      let(:resource) { build_stubbed(model_name, absolute_time: nil, entered_time: "16:30:45") }

      it "returns the entered_time in hh:mm:ss format" do
        expect(result).to eq("16:30:45")
      end
    end
  end

  describe "#sub_split_kind" do
    context "when bitkey is the in_bitkey" do
      let(:raw_time) { RawTime.new(bitkey: in_bitkey) }

      it 'returns "in" when bitkey is the in_bitkey' do
        expect(raw_time.sub_split_kind).to eq("In")
      end
    end

    context "when bitkey is the out_bitkey" do
      let(:raw_time) { RawTime.new(bitkey: out_bitkey) }

      it 'returns "in" when bitkey is the in_bitkey' do
        expect(raw_time.sub_split_kind).to eq("Out")
      end
    end
  end

  describe "#sub_split_kind=" do
    context 'when sub_split_kind is "in"' do
      let(:sub_split_kind) { "in" }

      it "sets the bitkey to the in_bitkey" do
        raw_time = RawTime.new(sub_split_kind: sub_split_kind)
        expect(raw_time.bitkey).to eq(in_bitkey)
      end
    end

    context 'when sub_split_kind is "out"' do
      let(:sub_split_kind) { "out" }

      it "sets the bitkey to the in_bitkey" do
        raw_time = RawTime.new(sub_split_kind: sub_split_kind)
        expect(raw_time.bitkey).to eq(out_bitkey)
      end
    end

    context "when sub_split_kind has different capitalization" do
      let(:sub_split_kind) { "OUT" }

      it "sets the bitkey as expected" do
        raw_time = RawTime.new(sub_split_kind: sub_split_kind)
        expect(raw_time.bitkey).to eq(out_bitkey)
      end
    end

    context "when sub_split_kind is a symbol" do
      let(:sub_split_kind) { :out }

      it "sets the bitkey as expected" do
        raw_time = RawTime.new(sub_split_kind: sub_split_kind)
        expect(raw_time.bitkey).to eq(out_bitkey)
      end
    end

    context "when sub_split_kind is an empty string" do
      let(:sub_split_kind) { "" }

      it "sets the bitkey to nil" do
        raw_time = RawTime.new(sub_split_kind: sub_split_kind)
        expect(raw_time.bitkey).to eq(nil)
      end
    end

    context "when sub_split_kind is nil" do
      let(:sub_split_kind) { nil }

      it "sets the bitkey to nil" do
        raw_time = RawTime.new(sub_split_kind: sub_split_kind)
        expect(raw_time.bitkey).to eq(nil)
      end
    end
  end
end
