require "rails_helper"

# t.integer  "event_id"
# t.integer  "participant_id"
# t.string   "wave"
# t.integer  "bib_number"
# t.string   "city"
# t.string   "state"
# t.integer  "country_id"
# t.integer  "age"
# t.datetime "start_time"
# t.boolean  "dropped"

RSpec.describe Effort, type: :model do
  it "should be valid when created with an event_id, a participant_id, and a start time" do
    event = Event.create!(course_id: 1, name: 'Hardrock 2015', first_start_time: "2015-07-01 06:00:00")
    participant = Participant.create!(first_name: 'Dave', last_name: 'Mitchell', gender: 'male')
    Effort.create!(event_id: event.id, participant_id: participant.id, start_time: "2015-07-01 06:00:00")

    expect(Effort.all.count).to(equal(1))
    expect(Effort.first.event_id).to eq(event.id)
    expect(Effort.first.participant_id).to eq(participant.id)
  end

  it "should be invalid without an event_id" do
    effort = Effort.new(event_id: nil, participant_id: 1, start_time: "2015-07-01 06:00:00")
    expect(effort).not_to be_valid
    expect(effort.errors[:event_id]).to include("can't be blank")
  end

  it "should be invalid without a participant_id" do
    effort = Effort.new(event_id: 1, participant_id: nil, start_time: "2015-07-01 06:00:00")
    expect(effort).not_to be_valid
    expect(effort.errors[:participant_id]).to include("can't be blank")
  end

  it "should be invalid without a start time" do
    effort = Effort.new(event_id: 1, participant_id: 1, start_time: nil)
    expect(effort).not_to be_valid
    expect(effort.errors[:start_time]).to include("can't be blank")
  end

  it "should not permit more than one effort by a participant in a given event" do
    Effort.create!(event_id: 1, participant_id: 1, start_time: "2015-07-01 06:00:00")
    effort = Effort.new(event_id: 1, participant_id: 1, start_time: "2015-07-01 06:00:00")
    expect(effort).not_to be_valid
    expect(effort.errors[:participant_id]).to include("has already been taken")
  end

  it "should not permit duplicate bib_numbers within a given event" do
    Effort.create!(event_id: 1, participant_id: 1, bib_number: 20, start_time: "2015-07-01 06:00:00")
    effort = Effort.new(event_id: 1, participant_id: 2, bib_number: 20, start_time: "2015-07-01 06:00:00")
    expect(effort).not_to be_valid
    expect(effort.errors[:bib_number]).to include("has already been taken")
  end

  it "should reject invalid country_id" do
    effort = Effort.new(event_id: 1, participant_id: 2, country_id: 1000, start_time: "2015-07-01 06:00:00")
    expect(effort).not_to be_valid
    expect(effort.errors[:country]).to include("can't be blank")
  end

end