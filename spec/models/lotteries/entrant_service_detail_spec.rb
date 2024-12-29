# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lotteries::EntrantServiceDetail do
  describe "#accepted?" do
    let(:result) { subject.accepted? }

    context "when form_accepted_at is nil" do
      subject { build(:lotteries_entrant_service_detail) }
      it { expect(result).to eq(false) }
    end

    context "when form_accepted_at is not nil" do
      subject { build(:lotteries_entrant_service_detail, :accepted) }
      it { expect(result).to eq(true) }
    end
  end

  describe "#rejected?" do
    let(:result) { subject.rejected? }

    context "when form_rejected_at is nil" do
      subject { build(:lotteries_entrant_service_detail) }
      it { expect(result).to eq(false) }
    end

    context "when form_rejected_at is not nil" do
      subject { build(:lotteries_entrant_service_detail, :rejected) }
      it { expect(result).to eq(true) }
    end
  end

  describe "#status" do
    let(:result) { subject.status }

    context "when the form has been accepted" do
      subject { build(:lotteries_entrant_service_detail, :accepted) }

      it { expect(result).to eq("accepted") }
    end

    context "when the form has been rejected" do
      subject { build(:lotteries_entrant_service_detail, :rejected) }

      it { expect(result).to eq("rejected") }
    end

    context "when the form has not been accepted or rejected" do
      subject { build(:lotteries_entrant_service_detail) }

      it { expect(result).to eq("under_review") }
    end
  end
end
