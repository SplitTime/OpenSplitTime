require "rails_helper"

RSpec.describe BasePresenter do
  subject { presenter_class.new(prepared_params) }

  let(:presenter_class) do
    Class.new(described_class) do
      def initialize(params) # rubocop:disable Lint/MissingSuper -- the parent initializer raises NotImplementedError
        @params = params
      end

      private

      attr_reader :params
    end
  end

  let(:prepared_params) { PreparedParams.new(ActionController::Parameters.new(query_params), [], []) }

  describe "#page" do
    let(:result) { subject.page }

    context "when page is not provided" do
      let(:query_params) { {} }
      it { expect(result).to eq(1) }
    end

    context "when page is zero" do
      let(:query_params) { { page: "0" } }
      it { expect(result).to eq(1) }
    end

    context "when page is positive" do
      let(:query_params) { { page: "3" } }
      it { expect(result).to eq(3) }
    end

    context "when page is negative" do
      let(:query_params) { { page: "-11" } }
      it { expect(result).to eq(1) }
    end

    context "when page is a SQL injection probe" do
      let(:query_params) { { page: "-11' UNION ALL SELECT NULL,NULL--" } }
      it { expect(result).to eq(1) }
    end
  end

  describe "#per_page" do
    let(:result) { subject.per_page }

    context "when per_page is not provided" do
      let(:query_params) { {} }
      it { expect(result).to eq(described_class::DEFAULT_PER_PAGE) }
    end

    context "when per_page is zero" do
      let(:query_params) { { per_page: "0" } }
      it { expect(result).to eq(described_class::DEFAULT_PER_PAGE) }
    end

    context "when per_page is positive" do
      let(:query_params) { { per_page: "25" } }
      it { expect(result).to eq(25) }
    end

    context "when per_page is negative" do
      let(:query_params) { { per_page: "-5" } }
      it { expect(result).to eq(described_class::DEFAULT_PER_PAGE) }
    end
  end
end
