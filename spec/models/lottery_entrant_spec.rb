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

  describe "drawn and undrawn scopes" do
    let(:existing_scope) { division.entrants }
    let(:division) { LotteryDivision.find_by(name: division_name) }

    describe ".drawn" do
      let(:result) { existing_scope.drawn }

      context "when the existing scope includes entrants who have been drawn" do
        let(:division_name) { "Never Ever Evers" }
        it "returns a collection of all relevant entrants" do
          expect(result.count).to eq(5)
          expect(result.map(&:first_name)).to match_array(["Mitsuko", "Jospeh", "Nenita", "Emeline", "Modesta"])
        end
      end

      context "when the existing scope does not include entrants who have been drawn" do
        let(:division_name) { "Veterans" }
        it "returns an empty collection" do
          expect(result).to be_empty
        end
      end
    end

    describe ".undrawn" do
      let(:result) { existing_scope.undrawn }

      context "when the existing scope includes entrants who have not been drawn" do
        let(:division_name) { "Elses" }
        it "returns a collection of all undrawn entrants" do
          expect(result.count).to eq(3)
          expect(result.map(&:first_name)).to match_array(["Shenika", "Abraham", "Maud"])
        end
      end

      context "when the existing scope entrants have all been drawn" do
        before { division.draw_ticket! }
        let(:division_name) { "Never Ever Evers" }

        it "returns an empty collection" do
          expect(result).to be_empty
        end
      end
    end
  end

  describe "validations" do
    let(:new_entrant) do
      ::LotteryEntrant.new(division: division, first_name: first_name, last_name: last_name, birthdate: birthdate, gender: :male, number_of_tickets: 1)
    end
    let(:existing_entrant_lottery) { lotteries(:lottery_without_tickets) }
    let(:existing_entrant_division) { existing_entrant_lottery.divisions.find_by(name: "Slow People") }
    let(:same_lottery_other_division) { existing_entrant_lottery.divisions.find_by(name: "Fast People") }
    let(:existing_entrant) { existing_entrant_division.entrants.find_by(first_name: "Deb") }
    let(:different_lottery) { lotteries(:lottery_with_tickets_and_draws) }
    let(:different_lottery_division) { different_lottery.divisions.find_by(name: "Elses") }

    context "when the entrant key matches a key in the same division" do
      let(:division) { existing_entrant.division }
      let(:first_name) { existing_entrant.first_name }
      let(:last_name) { existing_entrant.last_name }
      let(:birthdate) { existing_entrant.birthdate }
      it "is not valid" do
        expect(new_entrant).not_to be_valid
        expect(new_entrant.errors.full_messages).to include /has already been entered/
      end
    end

    context "when the entrant key matches a key in the same lottery but a different division" do
      let(:division) { same_lottery_other_division }
      let(:first_name) { existing_entrant.first_name }
      let(:last_name) { existing_entrant.last_name }
      let(:birthdate) { existing_entrant.birthdate }
      it "is not valid" do
        expect(new_entrant).not_to be_valid
        expect(new_entrant.errors.full_messages).to include /has already been entered/
      end
    end

    context "when the entrant key matches a key in a different lottery" do
      let(:division) { different_lottery_division }
      let(:first_name) { existing_entrant.first_name }
      let(:last_name) { existing_entrant.last_name }
      let(:birthdate) { existing_entrant.birthdate }
      it "is valid" do
        expect(new_entrant).to be_valid
      end
    end
  end

  describe "#draw_ticket!" do
    subject { lottery.entrants.find_by(last_name: "Crona") }
    let(:lottery) { lotteries(:lottery_without_tickets) }
    let(:execute_method) { subject.draw_ticket! }

    context "when the entrant has no tickets" do
      it "does not create a draw" do
        expect { execute_method }.not_to change { LotteryDraw.count }
      end

      it "returns nil" do
        expect(execute_method).to be_nil
      end
    end

    context "when the entrant has tickets that have not been drawn" do
      before { lottery.delete_and_insert_tickets! }
      it "creates a draw" do
        expect { execute_method }.to change { LotteryDraw.count }.by(1)
      end

      it "returns the draw" do
        expect(execute_method).to be_a(LotteryDraw)
      end
    end

    context "when the entrant has already been drawn" do
      before do
        lottery.delete_and_insert_tickets!
        lottery.draws.create(ticket: subject.tickets.first)
      end

      it "does not create a draw" do
        expect { execute_method }.not_to change { LotteryDraw.count }
      end

      it "returns nil" do
        expect(execute_method).to be_nil
      end
    end
  end

  describe "#drawn?" do
    subject { lottery.entrants.find_by(last_name: "Crona") }
    let(:lottery) { lotteries(:lottery_without_tickets) }
    let(:result) { subject.drawn? }

    context "when the entrant has no tickets" do
      it { expect(result).to eq(false) }
    end

    context "when the entrant has tickets that have not been drawn" do
      before { lottery.delete_and_insert_tickets! }
      it { expect(result).to eq(false) }
    end

    context "when the entrant has been drawn" do
      before do
        lottery.delete_and_insert_tickets!
        lottery.draws.create(ticket: subject.tickets.first)
      end

      it { expect(result).to eq(true) }
    end
  end
end
