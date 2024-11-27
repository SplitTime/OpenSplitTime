# frozen_string_literal: true

require "rails_helper"

RSpec.describe HistoricalFact, type: :model do
  it_behaves_like "auditable"
  it_behaves_like "matchable"
  it_behaves_like "state_country_syncable"

  it { is_expected.to capitalize_attribute(:first_name) }
  it { is_expected.to capitalize_attribute(:last_name) }
  it { is_expected.to capitalize_attribute(:city) }
  it { is_expected.to strip_attribute(:first_name).collapse_spaces }
  it { is_expected.to strip_attribute(:last_name).collapse_spaces }
  it { is_expected.to strip_attribute(:address).collapse_spaces }
  it { is_expected.to strip_attribute(:city).collapse_spaces }
  it { is_expected.to strip_attribute(:state_code).collapse_spaces }
  it { is_expected.to strip_attribute(:country_code).collapse_spaces }
  it { is_expected.to strip_attribute(:comments).collapse_spaces }

  describe "callbacks" do
    subject { build(:historical_fact) }

    it "creates a personal_info_hash when a new record is created" do
      expect(subject.personal_info_hash).to be_nil
      subject.save!
      expect(subject.personal_info_hash).not_to be_nil
    end

    it "updates the personal_info_hash when an existing record is updated" do
      subject.save!
      subject.first_name = subject.first_name + "(updated)"
      expect { subject.save! }.to change { subject.personal_info_hash }
    end
  end

  describe "scopes" do
    describe ".by_kind" do
      subject { described_class.by_kind(kinds) }

      let(:kinds) { [] }
      let!(:fact_1) { create(:historical_fact, kind: :dns) }
      let!(:fact_2) { create(:historical_fact, kind: :dnf) }
      let!(:fact_3) { create(:historical_fact, kind: :finished) }

      context "when kinds is an empty array" do
        it "returns all historical facts" do
          expect(subject.count).to eq(HistoricalFact.count)
        end
      end

      context "when kinds is nil" do
        let(:kinds) { nil }

        it "returns all historical facts" do
          expect(subject.count).to eq(HistoricalFact.count)
        end
      end

      context "when kinds contains a single value" do
        let(:kinds) { [:dns] }

        it "returns historical facts having that kind" do
          expect(subject.count).to eq(1)
          expect(subject.first.kind).to eq("dns")
        end
      end

      context "when kinds contains more than one value" do
        let(:kinds) { [:dns, :dnf] }

        it "returns historical facts having those kinds" do
          expect(subject.count).to eq(2)
          expect(subject.pluck(:kind)).to match_array %w[dns dnf]
        end
      end

      context "when kinds contains all available values" do
        let(:kinds) { [:dns, :dnf, :finished] }

        it "returns all historical facts" do
          expect(subject.count).to eq(3)
          expect(subject.pluck(:kind)).to match_array %w[dns dnf finished]
        end
      end
    end

    describe ".by_reconciled" do
      subject { described_class.by_reconciled(reconciled_booleans) }

      let(:reconciled_booleans) { nil }
      let!(:fact_1) { create(:historical_fact, person: person) }
      let!(:fact_2) { create(:historical_fact, person: nil) }
      let(:person) { people(:bruno_fadel) }

      context "when reconciled_booleans is nil" do
        it "returns all historical facts" do
          expect(subject.count).to eq(HistoricalFact.count)
        end
      end

      context "when reconciled_booleans is false" do
        let(:reconciled_booleans) { false }

        it "returns historical facts that are not reconciled" do
          expect(subject.count).to eq(1)
          expect(subject.first).to eq(fact_2)
        end
      end

      context "when reconciled_booleans is true" do
        let(:reconciled_booleans) { true }

        it "returns historical facts that are reconciled" do
          expect(subject.count).to eq(1)
          expect(subject.first).to eq(fact_1)
        end
      end

      context "when reconciled_booleans is anything else" do
        let(:reconciled_booleans) { "nonsense" }

        it "returns all historical facts" do
          expect(subject.count).to eq(HistoricalFact.count)
        end
      end
    end
  end
end
