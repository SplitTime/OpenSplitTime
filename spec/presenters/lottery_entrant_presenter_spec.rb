# frozen_string_literal: true

require "rails_helper"

RSpec.describe LotteryEntrantPresenter do
  subject { described_class.new(entrant) }
  let(:entrant) { lottery_entrants(:lottery_entrant_0001) }
  let(:organization) { entrant.division.lottery.organization }

  describe "#service_manageable_by_user?" do
    let(:result) { subject.service_manageable_by_user?(user) }

    context "when the user is an admin" do
      let(:user) { users(:admin_user) }

      it { expect(result).to eq(true) }
    end

    context "when the user is not an admin" do
      let(:user) { users(:third_user) }

      context "when the user is a steward" do
        before { organization.stewards << user }

        it { expect(result).to eq(true) }
      end

      context "when the user has the same email as the entrant" do
        before { user.update(email: entrant.email) }

        it { expect(result).to eq(true) }
      end

      context "when the user is associated with the same person as the entrant" do
        let(:person) { people(:bruno_fadel) }

        before do
          person.update(claimant: user)
          entrant.update(person: person)
        end

        it { expect(result).to eq(true) }
      end

      context "when the user is not associated with the entrant" do
        it { expect(result).to eq(false) }
      end
    end

    context "when the user is nil" do
      let(:user) { nil }

      it { expect(result).to eq(false) }
    end
  end
end
