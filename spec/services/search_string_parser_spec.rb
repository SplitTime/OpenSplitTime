# frozen_string_literal: true

RSpec.describe SearchStringParser, type: :model do
  subject { described_class.new(search_string) }
  let(:search_string) { nil }

  describe "#number_component" do
    let(:result) { subject.number_component }
    context "when the search string is nil" do
      it "returns empty string" do
        expect(result).to eq("")
      end
    end

    context "when the search string is an empty string" do
      let(:search_string) { "" }
      it "returns empty string" do
        expect(result).to eq("")
      end
    end

    context "when the search string contains only words" do
      let(:search_string) { "John Doe" }
      it "returns empty string" do
        expect(result).to eq("")
      end
    end

    context "when the search string contains only integers" do
      let(:search_string) { "123 456" }
      it "returns the integers" do
        expect(result).to eq("123 456")
      end
    end

    context "when the search string contains a single integer" do
      let(:search_string) { "John Doe 123" }
      it "returns a string containing only that integer" do
        expect(result).to eq("123")
      end
    end

    context "when the search string contains multiple integers" do
      let(:search_string) { "John 123 Doe 456" }
      it "returns a string containing both integers" do
        expect(result).to eq("123 456")
      end
    end
  end

  describe "#word_component" do
    let(:result) { subject.word_component }
    context "when the search string is nil" do
      it "returns empty string" do
        expect(result).to eq("")
      end
    end

    context "when the search string is an empty string" do
      let(:search_string) { "" }
      it "returns empty string" do
        expect(result).to eq("")
      end
    end

    context "when the search string contains only words" do
      let(:search_string) { "John Doe" }
      it "returns the words downcased" do
        expect(result).to eq("john doe")
      end
    end

    context "when the search string contains only integers" do
      let(:search_string) { "123 456" }
      it "returns empty string" do
        expect(result).to eq("")
      end
    end

    context "when the search string contains a single integer" do
      let(:search_string) { "John Doe 123" }
      it "returns a string containing only the downcased words" do
        expect(result).to eq("john doe")
      end
    end

    context "when the search string contains multiple integers" do
      let(:search_string) { "John 123 Doe 456" }
      it "returns a string containing only the downcased words" do
        expect(result).to eq("john doe")
      end
    end
  end
end
