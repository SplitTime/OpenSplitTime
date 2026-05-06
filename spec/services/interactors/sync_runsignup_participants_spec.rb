require "rails_helper"

RSpec.describe Interactors::SyncRunsignupParticipants do
  subject(:sync) { described_class.perform!(event, current_user) }

  let(:event_group) { event_groups(:rufa_2017) }
  let(:event) { events(:rufa_2017_24h) }
  let(:current_user) { users(:admin_user) }

  let!(:event_connection) do
    Connection.create!(service_identifier: :runsignup, source_type: "Event", source_id: "24", destination: event)
  end

  let(:participant) do
    Connectors::Runsignup::Models::Participant.new(
      first_name: "Last",
      last_name: "Minute",
      birthdate: Date.new(1990, 1, 1),
      gender: "male",
      bib_number: participant_bib_number,
      city: "Denver",
      state_code: "CO",
      country_code: "US",
      email: "last.minute@example.com",
      phone: "3035551212",
      scheduled_start_time_local: event.scheduled_start_time_local,
    )
  end

  let!(:effort) do
    create(:effort,
           event: event,
           first_name: participant.first_name,
           last_name: participant.last_name,
           birthdate: participant.birthdate,
           bib_number: ost_bib_number,)
  end

  before do
    Connection.create!(service_identifier: :runsignup, source_type: "Race", source_id: "123", destination: event_group)
    allow(Connectors::Runsignup::FetchEventParticipants).to receive(:perform).and_return([participant])
  end

  context "when Runsignup participant has no bib number" do
    let(:participant_bib_number) { nil }

    context "when OST effort has a bib number" do
      let(:ost_bib_number) { 999 }

      it "preserves the OST bib number" do
        expect { sync }.not_to(change { effort.reload.bib_number })
      end
    end
  end

  context "when Runsignup participant has a bib number" do
    let(:participant_bib_number) { 123 }

    context "when OST effort has a different bib number" do
      let(:ost_bib_number) { 999 }

      it "overwrites the OST bib number with the Runsignup bib number" do
        sync
        expect(effort.reload.bib_number).to eq(123)
      end
    end

    context "when OST effort has no bib number" do
      let(:ost_bib_number) { nil }

      it "assigns the Runsignup bib number to the OST effort" do
        sync
        expect(effort.reload.bib_number).to eq(123)
      end
    end
  end

  describe "field_mappings flow-through" do
    let(:participant_bib_number) { 7 }
    let(:ost_bib_number) { nil }
    let(:field_mappings) do
      [{ "source_question_id" => 100, "destination" => "comments" }]
    end

    let(:returned_participant) do
      Connectors::Runsignup::Models::Participant.new(
        first_name: participant.first_name,
        last_name: participant.last_name,
        birthdate: participant.birthdate,
        bib_number: participant_bib_number,
        comments: "Lifelong cyclist",
        emergency_contact: "Pat Smith",
        emergency_phone: "303-555-1212",
      )
    end

    before do
      event_connection.update!(field_mappings: field_mappings)
      allow(Connectors::Runsignup::FetchEventParticipants).to receive(:perform).and_return([returned_participant])
    end

    it "passes the per-event-connection field_mappings into FetchEventParticipants" do
      sync
      expect(Connectors::Runsignup::FetchEventParticipants).to have_received(:perform).with(
        hash_including(field_mappings: field_mappings),
      )
    end

    it "writes the comments + emergency columns onto the Effort" do
      sync
      effort.reload
      expect(effort.comments).to eq("Lifelong cyclist")
      expect(effort.emergency_contact).to eq("Pat Smith")
      # Effort#normalize_emergency_phone strips non-digits before save.
      expect(effort.emergency_phone).to eq("3035551212")
    end
  end
end
