# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lottery, type: :model do
  it { is_expected.to strip_attribute(:name) }
  it { is_expected.to capitalize_attribute(:name) }

  describe "#generate_ticket_hashes" do
    subject { lotteries(:another_new_lottery) }
    let(:result) { subject.generate_ticket_hashes }
    let(:default_reference_number) { 100000 }

    it "returns an array the size of the aggregate sum of all tickets" do
      expect(result.size).to eq(4)
    end

    it "returns hashes with expected information" do
      expect(result.first[:lottery_id]).to eq(subject.id)
      expect(result.first[:reference_number]).to eq(default_reference_number)
    end
  end
end
