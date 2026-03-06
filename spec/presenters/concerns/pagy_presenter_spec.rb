require "rails_helper"

RSpec.describe PagyPresenter do
  # Create a test presenter class that includes the concern
  let(:test_presenter_class) do
    Class.new do
      include PagyPresenter

      attr_reader :view_context

      def initialize(view_context)
        @view_context = view_context
      end

      # Delegate request to view_context (like real presenters do)
      def request
        view_context.request
      end
    end
  end

  let(:request) { { params: { 'page' => '1', 'limit' => '25' } } }
  let(:view_context) { double("view_context", request: request) }
  subject { test_presenter_class.new(view_context) }

  describe "#pagy_from_scope" do
    let(:scope) { double("scope") }
    let(:count) { 100 }

    before do
      allow(scope).to receive(:reorder).and_return(scope)
      allow(scope).to receive(:count).and_return(count)
      allow(scope).to receive(:offset).and_return(scope)
      allow(scope).to receive(:limit).and_return(scope)
    end

    it "returns a pagy instance and paginated records" do
      request_with_page_2 = { params: { 'page' => '2', 'limit' => '25' } }
      pagy, records = subject.pagy_from_scope(scope, request_with_page_2)

      expect(pagy).to be_a(Pagy::Offset)
      expect(pagy.count).to eq(100)
      expect(pagy.page).to eq(2)
      expect(pagy.limit).to eq(25)
      expect(records).to eq(scope)
    end

    context "when count is provided" do
      it "does not query the scope for count" do
        expect(scope).not_to receive(:count)

        subject.pagy_from_scope(scope, request, count: 50)
      end
    end

    context "when scope returns a Hash count (from GROUP BY)" do
      let(:grouped_count) { { 1 => 10, 2 => 20, 3 => 30 } }

      before do
        allow(scope).to receive(:count).and_return(grouped_count)
      end

      it "sums the count values" do
        pagy, _records = subject.pagy_from_scope(scope, request)

        expect(pagy.count).to eq(60)
      end
    end
  end

  describe "#pagy_countless_from_scope" do
    let(:scope) { double("scope") }
    let(:records) { (1..26).to_a }

    before do
      allow(scope).to receive(:offset).and_return(scope)
      allow(scope).to receive(:limit).and_return(scope)
      allow(scope).to receive(:to_a).and_return(records)
    end

    it "returns a Pagy::Offset::Countless instance and paginated records" do
      pagy, paginated_records = subject.pagy_countless_from_scope(scope, request)

      expect(pagy).to be_a(Pagy::Offset::Countless)
      expect(pagy.page).to eq(1)
      expect(pagy.limit).to eq(25)
      expect(paginated_records.size).to eq(25)
    end

    it "does not raise an error despite global overflow setting" do
      # Pagy::Offset::Countless only supports :empty_page or :exception
      # This test ensures we explicitly override the overflow option
      expect do
        subject.pagy_countless_from_scope(scope, request)
      end.not_to raise_error
    end

    it "uses :empty_page overflow option for Pagy::Offset::Countless" do
      pagy, _records = subject.pagy_countless_from_scope(scope, request)

      expect(pagy.options[:overflow]).to eq(:empty_page)
    end

    context "when requesting a page beyond available data" do
      let(:records) { [] }

      it "returns an empty page without raising an error" do
        request_page_999 = { params: { 'page' => '999', 'limit' => '25' } }
        pagy, paginated_records = subject.pagy_countless_from_scope(scope, request_page_999)

        expect(pagy).to be_a(Pagy::Offset::Countless)
        expect(paginated_records).to be_empty
      end
    end
  end
end
