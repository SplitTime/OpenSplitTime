# frozen_string_literal: true

require "rails_helper"

RSpec.describe Interactors::SyncLotteryEntrants do
  subject { described_class.new(event) }
  let(:event_group) { create(:event_group, organization: organizations(:hardrock)) }
  let(:event) { create(:event, event_group: event_group, course: courses(:hardrock_cw), lottery_id: lottery_id) }
  let(:lottery_id) { nil }
  let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }

  shared_examples "returns a response with a descriptive error" do
    it "returns a descriptive error" do
      expect(response).not_to be_successful
      expect(response.errors.first.dig(:detail, :messages).first).to include("The event has not been linked to a lottery")
    end
  end

  shared_examples "returns expected response for no existing efforts" do
    it "returns a response containing expected resources" do
      expect(response).to be_a(::Interactors::Response)
      expect(response.errors).to be_empty

      created_efforts = response.resources[:created_efforts]
      expect(created_efforts.size).to eq(5)
      expect(created_efforts).to match_array(event.efforts.to_a)
    end
  end

  shared_examples "returns expected response for all non-matching efforts" do
    it "returns a response containing expected resources" do
      expect(response).to be_a(::Interactors::Response)
      expect(response.errors).to be_empty

      created_efforts = response.resources[:created_efforts]
      expect(created_efforts.size).to eq(5)

      deleted_efforts = response.resources[:deleted_efforts]
      expect(deleted_efforts.size).to eq(2)
      expect(deleted_efforts).to match_array([effort_1, effort_2])
    end
  end

  shared_examples "returns expected response for some matching and some non-matching efforts" do
    it "returns a response containing expected resources" do
      expect(response).to be_a(::Interactors::Response)
      expect(response.errors).to be_empty

      created_efforts = response.resources[:created_efforts]
      expect(created_efforts.size).to eq(3)

      updated_efforts = response.resources[:updated_efforts]
      expect(updated_efforts.size).to eq(2)
      expect(updated_efforts).to match_array([effort_1, effort_2])

      deleted_efforts = response.resources[:deleted_efforts]
      expect(deleted_efforts.size).to eq(1)
      expect(deleted_efforts).to eq([effort_3])
    end
  end

  describe ".perform!" do
    let(:response) { subject.perform! }
    context "when the event is not linked to a lottery" do
      include_examples "returns a response with a descriptive error"
    end

    context "when the event is linked to a lottery" do
      let(:lottery_id) { lottery.id }
      let(:resulting_effort_ids) { event.reload.efforts.pluck(:id) }

      context "when the event has no existing efforts" do
        it "adds all accepted lottery entrants to the event" do
          expect(event.efforts.count).to eq(0)
          expect(response.errors).to eq([])
          expect(event.efforts.count).to eq(5)
        end

        include_examples "returns expected response for no existing efforts"
      end

      context "when the event has existing efforts that do not match the lottery entrants" do
        let!(:effort_1) { create(:effort, event: event) }
        let!(:effort_2) { create(:effort, event: event) }

        it "destroys existing efforts and adds accepted lottery entrants" do
          expect(event.efforts.count).to eq(2)
          response
          expect(event.efforts.count).to eq(5)

          expect(effort_1.id).not_to be_in(resulting_effort_ids)
          expect(effort_2.id).not_to be_in(resulting_effort_ids)
        end

        include_examples "returns expected response for all non-matching efforts"
      end

      context "when the event has existing efforts some of which match the lottery entrants" do
        let(:entrant_1) { lottery_divisions(:lottery_division_1).accepted_entrants.first }
        let(:entrant_2) { lottery_divisions(:lottery_division_1).accepted_entrants.second }
        let!(:effort_1) { create(:effort, event: event, first_name: entrant_1.first_name, last_name: entrant_1.last_name, birthdate: entrant_1.birthdate) }
        let!(:effort_2) { create(:effort, event: event, first_name: entrant_2.first_name, last_name: entrant_2.last_name, birthdate: entrant_2.birthdate) }
        let!(:effort_3) { create(:effort, event: event) }

        it "matches and creates entrants as expected" do
          expect(event.efforts.count).to eq(3)
          response
          expect(event.efforts.count).to eq(5)

          expect(effort_1.id).to be_in(resulting_effort_ids)
          expect(effort_2.id).to be_in(resulting_effort_ids)
          expect(effort_3.id).not_to be_in(resulting_effort_ids)
        end

        include_examples "returns expected response for some matching and some non-matching efforts"
      end
    end
  end

  describe ".preview" do
    let(:response) { subject.preview }

    context "when the event is not linked to a lottery" do
      include_examples "returns a response with a descriptive error"
    end

    context "when the event is linked to a lottery" do
      let(:lottery_id) { lottery.id }

      context "when the event has no existing efforts" do
        it "makes no changes to the database" do
          expect(event.efforts.count).to eq(0)
          expect(response.errors).to eq([])
          expect(event.efforts.count).to eq(0)
        end

        include_examples "returns expected response for no existing efforts"
      end

      context "when the event has existing efforts that do not match the lottery entrants" do
        let!(:effort_1) { create(:effort, event: event) }
        let!(:effort_2) { create(:effort, event: event) }

        it "makes no changes to the database" do
          expect(event.efforts.count).to eq(2)
          response
          expect(event.efforts.count).to eq(2)
        end

        include_examples "returns expected response for all non-matching efforts"
      end

      context "when the event has existing efforts some of which match the lottery entrants" do
        let(:entrant_1) { lottery_divisions(:lottery_division_1).accepted_entrants.first }
        let(:entrant_2) { lottery_divisions(:lottery_division_1).accepted_entrants.second }
        let!(:effort_1) { create(:effort, event: event, first_name: entrant_1.first_name, last_name: entrant_1.last_name, birthdate: entrant_1.birthdate) }
        let!(:effort_2) { create(:effort, event: event, first_name: entrant_2.first_name, last_name: entrant_2.last_name, birthdate: entrant_2.birthdate) }
        let!(:effort_3) { create(:effort, event: event) }

        it "makes no changes to the database" do
          expect(event.efforts.count).to eq(3)
          response
          expect(event.efforts.count).to eq(3)
        end

        include_examples "returns expected response for some matching and some non-matching efforts"
      end
    end
  end
end
