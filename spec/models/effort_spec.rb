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
  it "should be valid when created with an event_id, a participant_id, and a start time" do
    event = Event.create!(course_id: 1, name: 'Hardrock 2015', start_date: "2015-07-01")
    participant = Participant.create!(first_name: 'Dave', last_name: 'Mitchell', gender: 'M')
    Effort.create!(event_id: event.id, participant_id: participant.id, start_time: "2015-07-01 06:00:00")

    expect(Effort.all.count).to(equal(1))
    expect(Effort.first.event_id).to eq(event.id)
    expect(Effort.first.participant_id).to eq(participant.id)
  end

  it "should be invalid without an event_id" do
    effort = Effort.new(event_id: nil, participant_id: 1, start_time: "2015-07-01 06:00:00")
    effort.valid?
    expect(effort.errors[:event_id].size).to eq(1)
  end

  it "should be invalid without a participant_id" do
    effort = Effort.new(event_id: 1, participant_id: nil, start_time: "2015-07-01 06:00:00")
    effort.valid?
    expect(effort.errors[:participant_id].size).to eq(1)
  end

  it "should be invalid without a start time" do
    effort = Effort.new(event_id: 1, participant_id: 1, start_time: nil)
    effort.valid?
    expect(effort.errors[:start_time].size).to eq(1)
  end

  it "should not permit more than one effort by a participant in a given event" do
    Effort.create!(event_id: 1, participant_id: 1, start_time: "2015-07-01 06:00:00")
    effort = Effort.new(event_id: 1, participant_id: 1, start_time: "2015-07-01 06:00:00")
    effort.valid?
    expect(effort.errors[:participant_id].size).to eq(1)
  end

end