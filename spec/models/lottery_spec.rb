require "rails_helper"

RSpec.describe Lottery, type: :model do
  subject { lotteries(:lottery_without_tickets) }

  it { is_expected.to strip_attribute(:name) }
  it { is_expected.to capitalize_attribute(:name) }

  describe "#delete_all_draws!" do
    let(:execute_method) { subject.delete_all_draws! }

    context "when no draws exist" do
      it "does nothing" do
        expect { execute_method }.not_to change { subject.draws.count }
      end
    end

    context "when draws exist" do
      subject { lotteries(:lottery_with_tickets_and_draws) }

      it "deletes all draws" do
        expect(subject.draws.count).not_to eq(0)
        expect { execute_method }.to change { subject.draws.count }.by(-subject.draws.count)
        expect(subject.draws.count).to eq(0)
        end
    end
  end

  describe "#delete_and_insert_tickets!" do
    let(:execute_method) { subject.delete_and_insert_tickets! }

    context "when no tickets exist" do
      before { expect(subject.tickets.count).to eq(0) }
      it "creates the expected number of tickets" do
        expected_ticket_count = subject.entrants.sum(:number_of_tickets)
        execute_method
        expect(subject.tickets.count).to eq(expected_ticket_count)
      end
    end

    context "when tickets exist" do
      before do
        expected_ticket_count = subject.entrants.sum(:number_of_tickets)
        execute_method
        expect(subject.tickets.count).to eq(expected_ticket_count)
      end

      it "deletes existing tickets" do
        existing_tickets = subject.tickets.to_a
        execute_method
        subject.reload
        existing_tickets.each { |ticket| expect(subject.tickets).not_to include(ticket) }
      end

      it "creates new tickets" do
        expected_ticket_count = subject.entrants.sum(:number_of_tickets)
        execute_method
        expect(subject.tickets.count).to eq(expected_ticket_count)
      end
    end
  end
end
