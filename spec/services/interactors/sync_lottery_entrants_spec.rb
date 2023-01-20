# frozen_string_literal: true

require "rails_helper"

RSpec.describe Interactors::SyncLotteryEntrants do
  describe ".perform!" do
    subject { described_class.new(event) }
    let(:event_group) { create(:event_group, organization: organizations(:hardrock)) }
    let(:event) { create(:event, event_group: event_group, course: courses(:hardrock_cw), lottery_id: lottery_id) }
    let(:lottery_id) { nil }
    let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }

    context "when the event is not linked to a lottery" do
      it "returns a descriptive error" do
        response = subject.perform!
        expect(response).not_to be_successful
        expect(response.errors.first.dig(:detail, :messages).first).to include("The event has not been linked to a lottery")
      end
    end

    context "when the event is linked to a lottery" do
      let(:lottery_id) { lottery.id }
      let(:resulting_effort_ids) { event.reload.efforts.pluck(:id) }

      context "when the event has no existing efforts" do
        it "adds all accepted lottery entrants to the event" do
          expect(event.efforts.count).to eq(0)
          subject.perform!
          expect(event.efforts.count).to eq(5)
        end
      end

      context "when the event has existing efforts that do not match the lottery entrants" do
        let!(:effort_1) { create(:effort, event: event) }
        let!(:effort_2) { create(:effort, event: event) }

        it "destroys existing efforts and adds accepted lottery entrants" do
          expect(event.efforts.count).to eq(2)
          subject.perform!
          expect(event.efforts.count).to eq(5)

          expect(effort_1.id).not_to be_in(resulting_effort_ids)
          expect(effort_2.id).not_to be_in(resulting_effort_ids)
        end
      end

      context "when the event has existing efforts some of which match the lottery entrants" do
        let(:entrant_1) { lottery_divisions(:lottery_division_1).accepted_entrants.first }
        let(:entrant_2) { lottery_divisions(:lottery_division_1).accepted_entrants.second }
        let!(:effort_1) { create(:effort, event: event, first_name: entrant_1.first_name, last_name: entrant_1.last_name, birthdate: entrant_1.birthdate) }
        let!(:effort_2) { create(:effort, event: event, first_name: entrant_2.first_name, last_name: entrant_2.last_name, birthdate: entrant_2.birthdate) }
        let!(:effort_3) { create(:effort, event: event) }

        it "matches and creates entrants as expected" do
          expect(event.efforts.count).to eq(3)
          subject.perform!
          expect(event.efforts.count).to eq(5)

          expect(effort_1.id).to be_in(resulting_effort_ids)
          expect(effort_2.id).to be_in(resulting_effort_ids)
          expect(effort_3.id).not_to be_in(resulting_effort_ids)
        end
      end
    end
  end
end
