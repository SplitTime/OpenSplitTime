require "rails_helper"

RSpec.describe Interactors::SyncRunsignupParticipants do
  subject(:sync) { described_class.perform!(event, current_user) }

  let(:event_group) { event_groups(:rufa_2017) }
  let(:event) { events(:rufa_2017_24h) }
  let(:current_user) { users(:admin_user) }

  let!(:race_connection) do
    Connection.create!(service_identifier: :runsignup, source_type: "Race", source_id: "123", destination: event_group)
  end

  let!(:event_connection) do
    Connection.create!(service_identifier: :runsignup, source_type: "Event", source_id: "24", destination: event)
  end

  let(:participant_attributes) do
    {
      first_name: "Last",
      last_name: "Minute",
      birthdate: Date.new(1990, 1, 1),
      gender: "male",
      city: "Denver",
      state_code: "CO",
      country_code: "US",
      email: "last.minute@example.com",
      phone: "3035551212",
      scheduled_start_time_local: event.scheduled_start_time_local,
    }
  end

  let(:participant_struct) do
    Struct.new(
      :first_name,
      :last_name,
      :birthdate,
      :gender,
      :bib_number,
      :city,
      :state_code,
      :country_code,
      :email,
      :phone,
      :scheduled_start_time_local,
      keyword_init: true,
    )
  end

  let(:participant) { participant_struct.new(**participant_attributes, bib_number: participant_bib_number) }

  let!(:effort) do
    create(:effort,
      event: event,
      first_name: participant.first_name,
      last_name: participant.last_name,
      birthdate: participant.birthdate,
      bib_number: ost_bib_number,
    )
  end

  before do
    allow(Connectors::Runsignup::FetchEventParticipants).to receive(:perform).and_return([participant])
  end

  context "when Runsignup participant has no bib number" do
    let(:participant_bib_number) { nil }

    context "when OST effort has a bib number" do
      let(:ost_bib_number) { 999 }

      it "preserves the OST bib number" do
        expect { sync }.not_to change { effort.reload.bib_number }
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
  end
end
