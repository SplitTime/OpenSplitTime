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

  describe "#age_range" do
    context "when low_age and high_age are nil" do
      subject(:results_category) { results_categories(:overall_men) }

      it "returns a range from 0 to infinity" do
        expect(subject.low_age).to be_nil
        expect(subject.high_age).to be_nil
        expect(subject.age_range).to eq(0..ResultsCategory::INF)
      end
    end

    context "when low_age is provided but high_age is nil" do
      subject(:results_category) { results_categories(:masters_men_40) }

      it "returns a range from the low_age to infinity" do
        expect(subject.low_age).to eq(40)
        expect(subject.high_age).to be_nil
        expect(subject.age_range).to eq(40..ResultsCategory::INF)
      end
    end

    context "when high_age is provided but low_age is nil" do
      subject(:results_category) { results_categories(:under_20_men) }

      it "returns a range from 0 to the high_age" do
        expect(subject.low_age).to eq(nil)
        expect(subject.high_age).to eq(19)
        expect(subject.age_range).to eq(0..19)
      end
    end
  end

  describe "#all_ages?" do
    context "when low_age is 0 and high_age is infinite" do
      subject(:results_category) { results_categories(:overall) }

      it { expect(subject.all_ages?).to eq(true) }
    end

    context "when any age is not covered" do
      subject(:results_category) { results_categories(:masters_men_40) }

      it { expect(subject.all_ages?).to eq(false) }
    end
  end

  describe "#genders" do
    context "when all genders are true" do
      subject(:results_category) { results_categories(:overall) }

      it { expect(subject.genders).to eq(%w[male female nonbinary]) }
    end

    context "when male is true and female and nonbinary are false" do
      subject(:results_category) { results_categories(:overall_men) }

      it { expect(subject.genders).to eq(%w[male]) }
    end

    context "when female is true and male and nonbinary are false" do
      subject(:results_category) { results_categories(:overall_women) }

      it { expect(subject.genders).to eq(%w[female]) }
    end

    context "when nonbinary is true and male and female are false" do
      subject(:results_category) { results_categories(:overall_nonbinary) }

      it { expect(subject.genders).to eq(%w[nonbinary]) }
    end
  end

  describe "#all_genders?" do
    context "when male, female, and nonbinary are true" do
      subject(:results_category) { results_categories(:overall) }

      it { expect(subject.all_genders?).to eq(true) }
    end

    context "when only male is true" do
      subject(:results_category) { results_categories(:overall_men) }

      it { expect(subject.all_genders?).to eq(false) }
    end

    context "when only female is true" do
      subject(:results_category) { results_categories(:overall_women) }

      it { expect(subject.all_genders?).to eq(false) }
    end

    context "when only nonbinary is true" do
      subject(:results_category) { results_categories(:overall_nonbinary) }

      it { expect(subject.all_genders?).to eq(false) }
    end
  end
end
