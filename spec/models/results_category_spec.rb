# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResultsCategory do
  it_behaves_like "auditable"

  subject(:results_category) { build(:results_category) }

  describe "#initialize" do
    it "saves a new record to the database" do
      expect(results_category).to be_valid
      expect { results_category.save }.to change { ResultsCategory.count }.by(1)
    end

    context "when no gender is true" do
      subject(:results_category) { build(:results_category, male: false, female: false, nonbinary: false) }

      it "is invalid" do
        expect(subject).not_to be_valid
        expect(subject.errors.full_messages).to include(/must include male or female or nonbinary entrants/)
      end
    end
  end

  describe "callbacks" do
    subject(:results_category) do
      build(:results_category, organization: organization, male: male, female: female, nonbinary: nonbinary, low_age: low_age, high_age: high_age)
    end

    let(:organization) { nil }
    let(:male) { false }
    let(:female) { false }
    let(:nonbinary) { false }
    let(:low_age) { nil }
    let(:high_age) { nil }

    describe "#set_identifier" do
      before { expect(subject).to be_valid }

      context "for all ages and genders" do
        let(:male) { true }
        let(:female) { true }
        let(:nonbinary) { true }

        it { expect(subject.identifier).to eq("combined_overall") }
      end

      context "for all ages of a single gender" do
        let(:male) { true }

        it { expect(subject.identifier).to eq("male_overall") }
      end

      context "for all ages of two genders" do
        let(:male) { true }
        let(:nonbinary) { true }

        it { expect(subject.identifier).to eq("male_nonbinary_overall") }
      end

      context "for a group with an upper age limit" do
        let(:male) { true }
        let(:high_age) { 19 }

        it { expect(subject.identifier).to eq("male_up_to_19") }
      end

      context "for a group with a lower age limit" do
        let(:male) { true }
        let(:low_age) { 19 }

        it { expect(subject.identifier).to eq("male_19_and_up") }
      end

      context "for a group with a lower and upper age limit" do
        let(:male) { true }
        let(:low_age) { 20 }
        let(:high_age) { 29 }

        it { expect(subject.identifier).to eq("male_20_to_29") }
      end

      context "for another group with a lower and upper age limit" do
        let(:female) { true }
        let(:low_age) { 40 }
        let(:high_age) { 49 }

        it { expect(subject.identifier).to eq("female_40_to_49") }
      end

      context "for a group with the same lower and upper age limit" do
        let(:female) { true }
        let(:low_age) { 40 }
        let(:high_age) { 40 }

        it { expect(subject.identifier).to eq("female_40") }
      end

      context "for a group with an organization" do
        let(:organization) { organizations(:hardrock) }
        let(:female) { true }
        let(:low_age) { 40 }

        it { expect(subject.identifier).to eq("hardrock_female_40_and_up") }
      end
    end

    describe "validate age range" do
      let(:male) { true }

      context "when low_age exists but high_age is nil" do
        let(:low_age) { 40 }

        it { expect(subject).to be_valid }
      end

      context "when high_age exists but low_age is nil" do
        let(:high_age) { 40 }

        it { expect(subject).to be_valid }
      end

      context "when low_age is greater than high_age" do
        let(:low_age) { 40 }
        let(:high_age) { 39 }

        it "is invalid" do
          expect(subject).not_to be_valid
          expect(subject.errors.full_messages).to include(/low age must be less than or equal to high age/)
        end
      end

      context "when low_age is equal to high_age" do
        let(:low_age) { 40 }
        let(:high_age) { 40 }

        it { expect(subject).to be_valid }
      end

      context "when low_age is less than high_age" do
        let(:low_age) { 39 }
        let(:high_age) { 40 }

        it { expect(subject).to be_valid }
      end
    end
  end

  describe "#age_range" do
    context "when low_age and high_age are nil" do
      subject(:results_category) { results_categories(:male_overall) }

      it "returns a range from 0 to infinity" do
        expect(subject.low_age).to be_nil
        expect(subject.high_age).to be_nil
        expect(subject.age_range).to eq(0..ResultsCategory::INF)
      end
    end

    context "when low_age is provided but high_age is nil" do
      subject(:results_category) { results_categories(:male_40_and_up) }

      it "returns a range from the low_age to infinity" do
        expect(subject.low_age).to eq(40)
        expect(subject.high_age).to be_nil
        expect(subject.age_range).to eq(40..ResultsCategory::INF)
      end
    end

    context "when high_age is provided but low_age is nil" do
      subject(:results_category) { results_categories(:male_up_to_19) }

      it "returns a range from 0 to the high_age" do
        expect(subject.low_age).to eq(nil)
        expect(subject.high_age).to eq(19)
        expect(subject.age_range).to eq(0..19)
      end
    end
  end

  describe "#all_ages?" do
    context "when low_age is 0 and high_age is infinite" do
      subject(:results_category) { results_categories(:combined_overall) }

      it { expect(subject.all_ages?).to eq(true) }
    end

    context "when any age is not covered" do
      subject(:results_category) { results_categories(:male_40_and_up) }

      it { expect(subject.all_ages?).to eq(false) }
    end
  end

  describe "#genders" do
    context "when all genders are true" do
      subject(:results_category) { results_categories(:combined_overall) }

      it { expect(subject.genders).to eq(%w[male female nonbinary]) }
    end

    context "when male is true and female and nonbinary are false" do
      subject(:results_category) { results_categories(:male_overall) }

      it { expect(subject.genders).to eq(%w[male]) }
    end

    context "when female is true and male and nonbinary are false" do
      subject(:results_category) { results_categories(:female_overall) }

      it { expect(subject.genders).to eq(%w[female]) }
    end

    context "when nonbinary is true and male and female are false" do
      subject(:results_category) { results_categories(:nonbinary_overall) }

      it { expect(subject.genders).to eq(%w[nonbinary]) }
    end
  end

  describe "#all_genders?" do
    context "when male, female, and nonbinary are true" do
      subject(:results_category) { results_categories(:combined_overall) }

      it { expect(subject.all_genders?).to eq(true) }
    end

    context "when only male is true" do
      subject(:results_category) { results_categories(:male_overall) }

      it { expect(subject.all_genders?).to eq(false) }
    end

    context "when only female is true" do
      subject(:results_category) { results_categories(:female_overall) }

      it { expect(subject.all_genders?).to eq(false) }
    end

    context "when only nonbinary is true" do
      subject(:results_category) { results_categories(:nonbinary_overall) }

      it { expect(subject.all_genders?).to eq(false) }
    end
  end
end
