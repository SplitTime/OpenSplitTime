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

  describe ".drawn" do
    let(:result) { existing_scope.drawn }
    let(:existing_scope) { division.entrants }
    let(:division) { LotteryDivision.find_by(name: division_name) }

    context "when the existing scope includes entrants who have been drawn" do
      let(:division_name) { "Never Ever Evers" }
      it "returns a collection of all relevant entrants" do
        expect(result.count).to eq(6)
        expect(result.map(&:first_name)).to match_array(["Mitsuko", "Jospeh", "Nenita", "Emeline", "Modesta", "Norris"])
      end
    end

    context "when the existing scope does not include entrants who have been drawn" do
      let(:division_name) { "Veterans" }
      it "returns an empty collection" do
        expect(result).to be_empty
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
