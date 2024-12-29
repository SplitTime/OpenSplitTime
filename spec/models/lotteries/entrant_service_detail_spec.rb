require "rails_helper"

RSpec.describe Lotteries::EntrantServiceDetail do
  describe "validations" do
    subject do
      build_stubbed(
        :lotteries_entrant_service_detail,
        form_accepted_at: form_accepted_at,
        form_accepted_comments: form_accepted_comments,
        form_rejected_at: form_rejected_at,
        form_rejected_comments: form_rejected_comments,
        completed_date: completed_date,
      )
    end

    let(:form_accepted_at) { nil }
    let(:form_accepted_comments) { nil }
    let(:form_rejected_at) { nil }
    let(:form_rejected_comments) { nil }
    let(:completed_date) { nil }

    context "when all attributes are blank" do
      it { expect(subject).to be_valid }
    end

    context "when all accepted attributes are present" do
      let(:form_accepted_at) { 2.days.ago }
      let(:form_accepted_comments) { "Good job" }
      let(:completed_date) { 2.days.ago }

      it { expect(subject).to be_valid }
    end

    context "when all rejected attributes are present" do
      let(:form_rejected_at) { 2.days.ago }
      let(:form_rejected_comments) { "Incomplete" }

      it { expect(subject).to be_valid }
    end

    context "when form_accepted_at is present but completed_date is blank" do
      let(:form_accepted_at) { 2.days.ago }

      it "is not valid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:completed_date]).to include(/must be present/)
      end
    end

    context "when form_accepted_at is blank but form_accepted_comments is present" do
      let(:form_accepted_comments) { "Nice work" }

      it "is not valid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:form_accepted_comments]).to include(/may not be present/)
      end
    end

    context "when form_accepted_at is blank but completed_date is present" do
      let(:completed_date) { 30.days.ago }

      it "is not valid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:completed_date]).to include(/may not be present/)
      end
    end

    context "when form_rejected_at is present but form_rejected_comments is blank" do
      let(:form_rejected_at) { 2.days.ago }

      it "is not valid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:form_rejected_comments]).to include(/must be present/)
      end
    end

    context "when form_rejected_at is blank but form_rejected_comments is present" do
      let(:form_rejected_comments) { "Incomplete" }

      it "is not valid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:form_rejected_comments]).to include(/may not be present/)
      end
    end
  end

  describe "#accepted?" do
    let(:result) { subject.accepted? }

    context "when form_accepted_at is nil" do
      subject { build_stubbed(:lotteries_entrant_service_detail) }
      it { expect(result).to eq(false) }
    end

    context "when form_accepted_at is not nil" do
      subject { build_stubbed(:lotteries_entrant_service_detail, :accepted) }
      it { expect(result).to eq(true) }
    end
  end

  describe "#rejected?" do
    let(:result) { subject.rejected? }

    context "when form_rejected_at is nil" do
      subject { build_stubbed(:lotteries_entrant_service_detail) }
      it { expect(result).to eq(false) }
    end

    context "when form_rejected_at is not nil" do
      subject { build_stubbed(:lotteries_entrant_service_detail, :rejected) }
      it { expect(result).to eq(true) }
    end
  end

  describe "#under_review?" do
    let(:result) { subject.under_review? }

    context "when form_accepted_at is present" do
      subject { build_stubbed(:lotteries_entrant_service_detail, :accepted) }
      it { expect(result).to eq(false) }
    end

    context "when form_rejected_at is present" do
      subject { build_stubbed(:lotteries_entrant_service_detail, :rejected) }
      it { expect(result).to eq(false) }
    end

    context "when form_accepted_at and form_rejected_at are not present" do
      subject { build_stubbed(:lotteries_entrant_service_detail) }
      it { expect(result).to eq(true) }
    end
  end

  describe "#status" do
    let(:result) { subject.status }

    context "when the form has been accepted" do
      subject { build_stubbed(:lotteries_entrant_service_detail, :accepted) }

      it { expect(result).to eq("accepted") }
    end

    context "when the form has been rejected" do
      subject { build_stubbed(:lotteries_entrant_service_detail, :rejected) }

      it { expect(result).to eq("rejected") }
    end

    context "when the form has not been accepted or rejected" do
      subject { build_stubbed(:lotteries_entrant_service_detail) }

      it { expect(result).to eq("under_review") }
    end
  end
end
