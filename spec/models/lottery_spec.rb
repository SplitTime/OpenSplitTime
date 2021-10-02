# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lottery, type: :model do
  subject { lotteries(:lottery_without_tickets) }

  it { is_expected.to strip_attribute(:name) }
  it { is_expected.to capitalize_attribute(:name) }

  describe "#generate_ticket_hashes" do
    let(:result) { subject.generate_ticket_hashes }
    let(:default_reference_number) { 10_000 }

    it "returns an array the size of the aggregate sum of all tickets" do
      expect(result.size).to eq(4)
    end

    it "returns hashes with expected information" do
      expect(result.first[:lottery_id]).to eq(subject.id)
      expect(result.first[:reference_number]).to eq(default_reference_number)
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
