require "rails_helper"

RSpec.describe Interactors::SyncLotteryEntrants do
  subject { described_class.new(event, current_user) }
  let(:event_group) { create(:event_group, organization: organizations(:hardrock)) }
  let(:event) { create(:event, event_group: event_group, course: courses(:hardrock_cw)) }
  let(:current_user) { users(:admin_user) }
  let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }
  let(:nevers_division) { lottery.divisions.find_by(name: "Never Ever Evers") }

  let(:created_efforts) { response.resources[:created_efforts] }
  let(:updated_efforts) { response.resources[:updated_efforts] }
  let(:ignored_efforts) { response.resources[:ignored_efforts] }
  let(:deleted_efforts) { response.resources[:deleted_efforts] }

  shared_examples "returns a response with a descriptive error" do
    it "returns a descriptive error" do
      expect(response).not_to be_successful
      expect(response.errors.first.dig(:detail, :messages).first).to include("The event has not been linked")
    end
  end

  shared_examples "returns expected response for no existing efforts" do
    it "returns a response containing expected resources" do
      expect(response).to be_a(::Interactors::Response)
      expect(response.errors).to be_empty

      expect(created_efforts.size).to eq(5)
      expect(created_efforts).to match_array(event.efforts.to_a)

      expect(updated_efforts.size).to eq(0)
      expect(ignored_efforts.size).to eq(0)
      expect(deleted_efforts.size).to eq(0)
    end
  end

  shared_examples "returns expected response for all non-matching efforts" do
    it "returns a response containing expected resources" do
      expect(response).to be_a(::Interactors::Response)
      expect(response.errors).to be_empty

      expect(created_efforts.size).to eq(5)
      expect(updated_efforts.size).to eq(0)
      expect(ignored_efforts.size).to eq(0)

      expect(deleted_efforts.size).to eq(2)
      expect(deleted_efforts).to match_array([effort_1, effort_2])
    end
  end

  shared_examples "returns expected response for some matching and some non-matching efforts" do
    it "returns a response containing expected resources" do
      expect(response).to be_a(::Interactors::Response)
      expect(response.errors).to be_empty

      expect(created_efforts.size).to eq(3)
      expect(ignored_efforts.size).to eq(0)

      expect(updated_efforts.size).to eq(2)
      expect(updated_efforts).to match_array([effort_1, effort_2])

      expect(deleted_efforts.size).to eq(1)
      expect(deleted_efforts).to eq([effort_3])
    end
  end

  shared_examples "returns expected response for ignored efforts" do
    it "returns a response containing expected resources" do
      expect(response).to be_a(::Interactors::Response)
      expect(response.errors).to be_empty

      expect(created_efforts.size).to eq(4)
      expect(updated_efforts.size).to eq(0)
      expect(deleted_efforts.size).to eq(0)

      expect(ignored_efforts.size).to eq(1)
      expect(ignored_efforts).to eq([effort_1])
    end
  end

  shared_examples "returns expected response for all kinds of efforts" do
    it "returns a response containing expected resources" do
      expect(response).to be_a(::Interactors::Response)
      expect(response.errors).to be_empty

      expect(created_efforts.size).to eq(3)

      expect(updated_efforts.size).to eq(1)
      expect(updated_efforts).to eq([updated_effort])

      expect(deleted_efforts.size).to eq(1)
      expect(deleted_efforts).to eq([deleted_effort])

      expect(ignored_efforts.size).to eq(1)
      expect(ignored_efforts).to eq([ignored_effort])
    end
  end

  shared_examples "makes no changes to the database" do
    it { expect { response }.not_to change { event.efforts.count } }
  end

  shared_context "existing efforts that do not match" do
    let!(:effort_1) { create(:effort, event: event) }
    let!(:effort_2) { create(:effort, event: event) }
  end

  shared_context "existing efforts some of which match" do
    let(:entrant_1) { nevers_division.accepted_entrants.first }
    let(:entrant_2) { nevers_division.accepted_entrants.second }
    let!(:effort_1) { create(:effort, event: event, first_name: entrant_1.first_name, last_name: entrant_1.last_name, birthdate: entrant_1.birthdate) }
    let!(:effort_2) { create(:effort, event: event, first_name: entrant_2.first_name, last_name: entrant_2.last_name, birthdate: entrant_2.birthdate) }
    let!(:effort_3) { create(:effort, event: event) }
  end

  shared_context "existing effort that does not need updating" do
    let(:entrant_1) { nevers_division.accepted_entrants.first }
    let!(:effort_1) do
      create(
        :effort,
        event: event,
        first_name: entrant_1.first_name,
        last_name: entrant_1.last_name,
        birthdate: entrant_1.birthdate,
        gender: entrant_1.gender,
        city: entrant_1.city,
        state_code: entrant_1.state_code,
        country_code: entrant_1.country_code,
      )
    end
  end

  shared_context "existing efforts of all kinds" do
    let(:entrant_1) { nevers_division.accepted_entrants.first }
    let(:entrant_2) { nevers_division.accepted_entrants.second }
    let!(:ignored_effort) do
      create(
        :effort,
        event: event,
        first_name: entrant_1.first_name,
        last_name: entrant_1.last_name,
        birthdate: entrant_1.birthdate,
        gender: entrant_1.gender,
        city: entrant_1.city,
        state_code: entrant_1.state_code,
        country_code: entrant_1.country_code,
      )
    end

    let!(:updated_effort) do
      create(
        :effort,
        event: event,
        first_name: entrant_2.first_name,
        last_name: entrant_2.last_name,
        birthdate: entrant_2.birthdate,
      )
    end

    let!(:deleted_effort) { create(:effort, event: event) }
  end

  describe ".perform!" do
    let(:response) { subject.perform! }
    context "when the event is not linked to a lottery" do
      include_examples "returns a response with a descriptive error"
    end

    context "when the event is linked to a lottery" do
      let(:resulting_effort_ids) { event.reload.efforts.pluck(:id) }

      before do
        event.connections.create!(service_identifier: "internal_lottery", source_id: lottery.id, source_type: "Lottery")
      end

      context "when the event has no existing efforts" do
        it "adds all accepted lottery entrants to the event" do
          expect(event.efforts.count).to eq(0)
          expect(response.errors).to eq([])
          expect(event.efforts.count).to eq(5)
        end

        include_examples "returns expected response for no existing efforts"
      end

      context "when the event has existing efforts that do not match the lottery entrants" do
        include_context "existing efforts that do not match"

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
        include_context "existing efforts some of which match"

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

      context "when the event has an existing effort that matches but does not need updating" do
        include_context "existing effort that does not need updating"

        it "matches and creates entrants as expected" do
          expect(event.efforts.count).to eq(1)
          response
          expect(event.efforts.count).to eq(5)

          expect(effort_1.id).to be_in(resulting_effort_ids)
        end

        include_examples "returns expected response for ignored efforts"
      end

      context "when the event has efforts of all kinds" do
        include_context "existing efforts of all kinds"

        it "creates, updates, ignores, and deletes entrants as expected" do
          expect(event.efforts.count).to eq(3)
          response
          expect(event.efforts.count).to eq(5)

          expect(ignored_effort.id).to be_in(resulting_effort_ids)
          expect(updated_effort.id).to be_in(resulting_effort_ids)
          expect(deleted_effort.id).not_to be_in(resulting_effort_ids)
        end

        include_examples "returns expected response for all kinds of efforts"
      end
    end
  end

  describe ".preview" do
    let(:response) { subject.preview }

    context "when the event is not linked to a lottery" do
      include_examples "returns a response with a descriptive error"
    end

    context "when the event is linked to a lottery" do
      before do
        event.connections.create!(service_identifier: "internal_lottery", source_id: lottery.id, source_type: "Lottery")
      end

      context "when the event has no existing efforts" do
        include_examples "makes no changes to the database"
        include_examples "returns expected response for no existing efforts"
      end

      context "when the event has existing efforts that do not match the lottery entrants" do
        include_context "existing efforts that do not match"

        include_examples "makes no changes to the database"
        include_examples "returns expected response for all non-matching efforts"
      end

      context "when the event has existing efforts some of which match the lottery entrants" do
        include_context "existing efforts some of which match"

        include_examples "makes no changes to the database"
        include_examples "returns expected response for some matching and some non-matching efforts"
      end

      context "when the event has an existing effort that matches but does not need updating" do
        include_context "existing effort that does not need updating"

        include_examples "makes no changes to the database"
        include_examples "returns expected response for ignored efforts"
      end

      context "when the event has efforts of all kinds" do
        include_context "existing efforts of all kinds"

        include_examples "makes no changes to the database"
        include_examples "returns expected response for all kinds of efforts"
      end
    end
  end
end
