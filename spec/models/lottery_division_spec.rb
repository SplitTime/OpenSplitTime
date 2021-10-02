# frozen_string_literal: true

require "rails_helper"

RSpec.describe LotteryDivision, type: :model do
  it { is_expected.to strip_attribute(:name) }
  it { is_expected.to capitalize_attribute(:name) }

  describe "#draw_ticket!" do
    subject { lottery.divisions.find_by(name: "Slow People") }
    let(:lottery) { lotteries(:another_new_lottery) }
    let(:result) { subject.draw_ticket! }

    context "when no tickets have been created" do
      it "does not create a draw" do
        expect { result }.not_to change { LotteryDraw.count }
      end

      it "returns nil" do
        expect(result).to be_nil
      end
    end

    context "when there are tickets available" do
      before { lottery.delete_and_insert_tickets! }
      it "creates a draw" do
        expect { result }.to change { LotteryDraw.count }.by(1)
      end

      it "returns the created draw with expected attributes" do
        expect(result).to be_a(LotteryDraw)
        expect(result.lottery).to eq(lottery)
        expect(result.ticket.entrant.division).to eq(subject)
      end
    end

    context "when tickets have been created but have all been drawn" do
      before do
        lottery.delete_and_insert_tickets!
        number_of_tickets = subject.tickets.count
        expect(number_of_tickets).not_to eq(0)
        number_of_tickets.times { subject.draw_ticket! }
      end

      it "does not create a draw" do
        expect { result }.not_to change { LotteryDraw.count }
      end

      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end
end
