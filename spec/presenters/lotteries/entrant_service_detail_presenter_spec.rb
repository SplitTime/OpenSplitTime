require "rails_helper"

RSpec.describe Lotteries::EntrantServiceDetailPresenter do
  subject { described_class.new(service_detail) }
  let(:service_detail) { create(:lotteries_entrant_service_detail, :with_completed_form, entrant: entrant) }
  let(:entrant) { lottery_entrants(:lottery_entrant_0005) }
  let(:earlier_entrant) { lottery_entrants(:lottery_entrant_0002) }
  let(:later_entrant) { lottery_entrants(:lottery_entrant_0008) }

  describe "#next_entrant_for_review" do
    let(:result) { subject.next_entrant_for_review }

    context "when no other entrant needs review" do
      it { expect(result).to be_nil }
    end

    context "when an entrant with a lower id needs review but none with a higher id needs review" do
      before { create(:lotteries_entrant_service_detail, :with_completed_form, entrant: earlier_entrant) }
      it { expect(result).to be_nil }
    end

    context "when an entrant with a higher id needs review" do
      before { create(:lotteries_entrant_service_detail, :with_completed_form, entrant: later_entrant) }
      it { expect(result).to eq(later_entrant) }
    end
  end

  describe "#previous_entrant_for_review" do
    let(:result) { subject.previous_entrant_for_review }

    context "when no other entrant needs review" do
      it { expect(result).to be_nil }
    end

    context "when an entrant with a higher id needs review but none with a lower id needs review" do
      before { create(:lotteries_entrant_service_detail, :with_completed_form, entrant: later_entrant) }
      it { expect(result).to be_nil }
    end

    context "when an entrant with a lower id needs review" do
      before { create(:lotteries_entrant_service_detail, :with_completed_form, entrant: earlier_entrant) }
      it { expect(result).to eq(earlier_entrant) }
    end
  end
end
