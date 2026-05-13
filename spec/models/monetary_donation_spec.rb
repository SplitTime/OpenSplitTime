require "rails_helper"

RSpec.describe MonetaryDonation, type: :model do
  let(:hardrock) { organizations(:hardrock) }

  describe "associations" do
    it "belongs to an organization" do
      donation = described_class.new(organization: hardrock, received_on: Date.current, amount: 50, source: "paypal")

      expect(donation.organization).to eq(hardrock)
      expect(donation).to be_valid
    end

    it "is required to have an organization" do
      donation = described_class.new(received_on: Date.current, amount: 50, source: "paypal")

      expect(donation).not_to be_valid
      expect(donation.errors[:organization]).to be_present
    end

    it "is accessible through Organization#monetary_donations" do
      expect(hardrock.monetary_donations).to include(monetary_donations(:hardrock_paypal_2024))
    end
  end

  describe "validations" do
    subject { described_class.new(organization: hardrock, received_on: Date.current, amount: 50, source: "paypal") }

    it { is_expected.to be_valid }

    it "requires received_on" do
      subject.received_on = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:received_on]).to be_present
    end

    it "requires a positive amount" do
      subject.amount = 0
      expect(subject).not_to be_valid

      subject.amount = -10
      expect(subject).not_to be_valid

      subject.amount = nil
      expect(subject).not_to be_valid
    end

    it "requires source to be one of the enum values" do
      expect { subject.source = "wire" }.to raise_error(ArgumentError, /'wire' is not a valid source/)
    end
  end

  describe "source enum" do
    it "exposes the expected sources" do
      expect(described_class.sources.keys).to match_array(%w[paypal check bitpay other])
    end

    it "round-trips through the database" do
      donation = described_class.create!(organization: hardrock, received_on: Date.current, amount: 25, source: "check")

      expect(donation.reload.source).to eq("check")
      expect(donation).to be_check
    end
  end
end
