require "rails_helper"

# t.integer  "event_id"
# t.integer  "participant_id"
# t.string   "wave"
# t.integer  "bib_number"
# t.string   "effort_city"
# t.string   "effort_state"
# t.string   "effort_country"
# t.integer  "effort_age"
# t.datetime "start_time"
# t.boolean  "finished"
# t.datetime "created_at",     null: false
# t.datetime "updated_at",     null: false

RSpec.describe Effort, type: :model do
  it "should have an event and a participant" do
    event = Event.create!(name: 'Hardrock 2015')
    participant = Participant.create!(first_name: 'Dave', last_name: 'Mitchell')
    Effort.create!(event: event, participant: participant)

    expect(Effort.all.count).to(equal(1))
    expect(Effort.first.event_id).to eq(event.id)
    expect(Effort.first.participant_id).to eq(participant.id)
  end

end