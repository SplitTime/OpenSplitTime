require "rails_helper"

RSpec.describe Interactors::SyncRunsignupParticipants do
  let(:event_group) { event_groups(:rufa_2017) }
  let(:event) { events(:rufa_2017_24h) }
  let(:current_user) { users(:admin_user) }

  let(:participant) do
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
    ).new(
      first_name: "Last",
      last_name: "Minute",
      birthdate: Date.new(1990, 1, 1),
      gender: "male",
      bib_number: nil,
      city: "Denver",
      state_code: "CO",
      country_code: "US",
      email: "last.minute@example.com",
      phone: "3035551212",
      scheduled_start_time_local: event.scheduled_start_time_local,
    )
  end

  before do
    # Ensure Runsignup connections exist for validation + ID lookup
    Connection.create!(service_identifier: :runsignup, source_type: "Race", source_id: "123", destination: event_group)
    Connection.create!(service_identifier: :runsignup, source_type: "Event", source_id: "24", destination: event)

    allow(Connectors::Runsignup::FetchEventParticipants).to receive(:perform).and_return([participant])
  end

  it "does not blank out an OST bib_number when the Runsignup bib_number is empty" do
    effort = create(:effort,
      event: event,
      first_name: participant.first_name,
      last_name: participant.last_name,
      birthdate: participant.birthdate,
      bib_number: 999,
    )

    described_class.perform!(event, current_user)

    expect(effort.reload.bib_number).to eq(999)
  end

  it "overwrites the OST bib_number when the Runsignup bib_number is present" do
    participant_with_bib = participant.dup
    participant_with_bib.bib_number = 8888

    allow(Connectors::Runsignup::FetchEventParticipants).to receive(:perform).and_return([participant_with_bib])

    effort = create(:effort,
      event: event,
      first_name: participant.first_name,
      last_name: participant.last_name,
      birthdate: participant.birthdate,
      bib_number: 999,
    )

    response = described_class.perform!(event, current_user)

    expect(response).to be_successful
    expect(response.resources[:updated_efforts].map(&:id)).to include(effort.id)

    expect(effort.reload.bib_number).to eq(8888)
  end
end
