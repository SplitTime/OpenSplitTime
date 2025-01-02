require_relative "../../../lib/core_ext/string"
require "active_record"

RSpec.describe String do
  describe "#numeric?" do
    let(:result) { subject.numeric? }

    context "when the string is entirely digits" do
      subject { "1234" }
      it { expect(result).to eq(true) }
    end

    context "when the string represents a decimal" do
      subject { "1234.56" }
      it { expect(result).to eq(true) }
    end

    context "when the string is partially digits" do
      subject { "hello1234" }
      it { expect(result).to eq(false) }
    end

    context "when the string contains no digits" do
      subject { "hello" }
      it { expect(result).to eq(false) }
    end
  end

  describe "#numericize" do
    it "converts a string containing numbers to a float" do
      expect("5050.50".numericize).to eq(5050.5)
      expect("5050".numericize).to eq(5050.0)
    end

    it "removes commas and other non-numeric characters" do
      expect("14,000 feet".numericize).to eq(14_000)
      expect("$5.22".numericize).to eq(5.22)
    end

    it "returns 0.0 if no numeric content is contained" do
      expect("hello".numericize).to eq(0.0)
    end
  end

  describe "#to_boolean" do
    it "returns true when called on a true-ish string value" do
      true_strings = %w[1 t T true TRUE on ON].to_set
      true_strings.each do |string|
        expect(string.to_boolean).to eq(true)
      end
    end

    it "returns false when called on a false-ish string value" do
      false_strings = %w[0 f F false FALSE off OFF].to_set
      false_strings.each do |string|
        expect(string.to_boolean).to eq(false)
      end
    end

    it "returns nil when called on an empty string" do
      expect("".to_boolean).to eq(nil)
    end

    it "returns true when called on an unknown string value" do
      expect("hello".to_boolean).to eq(true)
    end
  end
end
