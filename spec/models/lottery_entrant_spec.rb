# frozen_string_literal: true

require "rails_helper"

RSpec.describe LotteryEntrant, type: :model do
  it { is_expected.to capitalize_attribute(:first_name) }
  it { is_expected.to capitalize_attribute(:last_name) }
  it { is_expected.to capitalize_attribute(:city) }
  it { is_expected.to strip_attribute(:first_name).collapse_spaces }
  it { is_expected.to strip_attribute(:last_name).collapse_spaces }
  it { is_expected.to strip_attribute(:city).collapse_spaces }
  it { is_expected.to strip_attribute(:state_code).collapse_spaces }
  it { is_expected.to strip_attribute(:country_code).collapse_spaces }

  describe ".drawn_and_ordered" do
    let(:result) { existing_scope.drawn_and_ordered }
    let(:existing_scope) { division.entrants }
    let(:division) { LotteryDivision.find_by(name: division_name) }

    context "when the existing scope includes entrants who have been drawn" do
      let(:division_name) { "Never Ever Evers" }
      it "returns a collection of all relevant entrants in the order they were drawn" do
        expect(result.count).to eq(6)
        expect(result.map(&:first_name)).to eq(["Mitsuko", "Jospeh", "Nenita", "Emeline", "Modesta", "Norris"])
      end
    end

    context "when the existing scope does not include entrants who have been drawn" do
      let(:division_name) { "Veterans" }
      it "returns an empty collection" do
        expect(result).to be_empty
      end
    end
  end
end
