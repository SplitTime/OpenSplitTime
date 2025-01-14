require "rails_helper"

RSpec.describe LotteryDivision, type: :model do
  subject { described_class.find_by(name: division_name) }
  let(:division_name) { "Slow People" }
  let(:lottery) { subject.lottery }

  it { is_expected.to strip_attribute(:name) }
  it { is_expected.to capitalize_attribute(:name) }

  describe "scopes" do
    describe ".with_drawn_tickets_count" do
      let(:result) { existing_scope.with_drawn_tickets_count }

      context "when existing scope is all divisions" do
        let(:existing_scope) { described_class }

        it "returns all divisions in the existing scope" do
          expect(result.count).to eq(described_class.count)
        end

        it "adds a drawn_tickets_count attribute to each division" do
          expect(result).to all respond_to(:drawn_tickets_count)
        end
      end

      context "when existing scope is the divisions of a single lottery" do
        let(:existing_scope) { lottery.divisions }

        context "when draws exist" do
          let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }

          it "returns each division with drawn ticket counts" do
            division1 = result.find { |division| division.name == "Elses" }
            division2 = result.find { |division| division.name == "Never Ever Evers" }
            division3 = result.find { |division| division.name == "Veterans" }

            expect(division1.drawn_tickets_count).to eq(2)
            expect(division2.drawn_tickets_count).to eq(5)
            expect(division3.drawn_tickets_count).to eq(0)
          end
        end

        context "when draws do not exist" do
          let(:lottery) { lotteries(:lottery_without_tickets) }

          it "returns each division with 0" do
            result.each do |division|
              expect(division.drawn_tickets_count).to eq(0)
            end
          end
        end
      end

      context "when existing scope is empty" do
        let(:existing_scope) { described_class.none }
        it { expect(result).to be_empty }
      end
    end
  end

  describe "#all_entrants_drawn?" do
    let(:result) { subject.all_entrants_drawn? }
    let(:division_name) { "Elses" }
    context "when all entrants have had a ticket drawn" do
      before do
        3.times { subject.draw_ticket! }
        expect(subject.entrants.count).to eq(subject.draws.count)
      end

      it "returns true" do
        expect(result).to eq(true)
      end
    end

    context "when some entrants have not had a ticket drawn" do
      it "returns false" do
        expect(result).to eq(false)
      end
    end
  end

  describe "#create_draw_for_ticket!" do
    let(:division_name) { "Elses" }
    let(:result) { subject.create_draw_for_ticket!(ticket) }

    context "when the ticket exists and has not been drawn" do
      let(:ticket) { subject.tickets.not_drawn.first }

      it "creates a draw" do
        expect { result }.to change { LotteryDraw.count }.by(1)
      end

      it "returns the draw" do
        expect(result).to be_a(LotteryDraw)
      end
    end

    context "when the ticket exists but has already been drawn" do
      let(:ticket) { subject.tickets.drawn.first }
      it "does not create a draw" do
        expect { result }.not_to change { LotteryDraw.count }
      end

      it "returns nil" do
        expect(result).to be_nil
      end
    end

    context "when the ticket does not exist" do
      let(:ticket) { nil }
      it "does not create a draw" do
        expect { result }.not_to change { LotteryDraw.count }
      end

      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end

  describe "#draw_ticket!" do
    let(:result) { subject.draw_ticket! }

    context "when no tickets have been created" do
      before { expect(lottery.tickets.count).to eq(0) }
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

  describe "#full?" do
    let(:result) { subject.full? }
    context "when the accepted list and wait list are full" do
      let(:division_name) { "Never Ever Evers" }
      it "returns true" do
        expect(result).to eq(true)
      end
    end

    context "when the accepted list is full but the wait list is not full" do
      let(:division_name) { "Elses" }
      before { 2.times { subject.draw_ticket! } }
      it "returns false" do
        expect(result).to eq(false)
      end
    end

    context "when the accepted list is not full" do
      let(:division_name) { "Elses" }
      it "returns false" do
        expect(result).to eq(false)
      end
    end

    context "when no tickets have been drawn" do
      let(:division_name) { "Veterans" }
      it "returns false" do
        expect(result).to eq(false)
      end
    end
  end

  describe "#waitlisted_entrants" do
    let(:result) { subject.waitlisted_entrants }

    context "when draws have spilled over into the wait list" do
      let(:division_name) { "Never Ever Evers" }
      it "returns wait listed entrants" do
        expect(result.count).to eq(2)
        expect(result).to all be_a(LotteryEntrant)
      end
    end

    context "when draws have not spilled over into the wait list" do
      let(:division_name) { "Elses" }
      it "returns an empty collection" do
        expect(result).to be_empty
      end
    end

    context "when no entrants have been drawn" do
      let(:division_name) { "Veterans" }
      it "returns an empty collection" do
        expect(result).to be_empty
      end
    end
  end

  describe "#accepted_entrants" do
    let(:result) { subject.accepted_entrants }

    context "when the accepted entrants have all been drawn" do
      let(:division_name) { "Never Ever Evers" }
      it "returns accepted entries equal in number to the maximum entries for the division" do
        expect(result.count).to eq(subject.maximum_entries)
        expect(result).to all be_a(LotteryEntrant)
      end

      context "when one of the entrants has withdrawn" do
        let(:withdrawn_entrant) { subject.entrants.accepted.first }
        before { withdrawn_entrant.update(withdrawn: true) }

        it "does not include the withdrawn entrant" do
          expect(result).not_to include(withdrawn_entrant)
        end
      end
    end

    context "when some accepted entrants have been drawn" do
      let(:division_name) { "Elses" }
      it "returns accepted entries equal in number to the total draws for the division" do
        expect(result.count).to eq(2)
        expect(result).to all be_a(LotteryEntrant)
      end
    end

    context "when no entrants have been drawn" do
      let(:division_name) { "Veterans" }
      it "returns an empty collection" do
        expect(result).to be_empty
      end
    end
  end
end
