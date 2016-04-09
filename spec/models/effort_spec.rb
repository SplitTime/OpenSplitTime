require "rails_helper"

# t.integer  "event_id"
# t.integer  "participant_id"
# t.string   "wave"
# t.integer  "bib_number"
# t.string   "city"
# t.string   "state_code"
# t.string  "country_code"
# t.integer  "age"
# t.datetime "start_time"
# t.boolean  "dropped"

RSpec.describe Effort, type: :model do
  it "should be valid when created with an event_id, first_name, last_name, gender, and start_time" do
    event = Event.create!(course_id: 1, name: 'Hardrock 2015', first_start_time: "2015-07-01 06:00:00")
    Effort.create!(event_id: event.id, first_name: 'David', last_name: 'Goliath', gender: 'male', start_time: event.first_start_time)

    expect(Effort.all.count).to(equal(1))
    expect(Effort.first.event_id).to eq(event.id)
    expect(Effort.first.last_name).to eq('Goliath')
  end

  it "should be invalid without an event_id" do
    effort = Effort.new(event_id: nil, first_name: 'David', last_name: 'Goliath', gender: 'male', start_time: "2015-07-01 06:00:00")
    expect(effort).not_to be_valid
    expect(effort.errors[:event_id]).to include("can't be blank")
  end

  it "should be invalid without a first_name" do
    effort = Effort.new(event_id: 1, first_name: nil, last_name: 'Appleseed', gender: 'male', start_time: "2015-07-01 06:00:00")
    expect(effort).not_to be_valid
    expect(effort.errors[:first_name]).to include("can't be blank")
  end

  it "should be invalid without a last_name" do
    effort = Effort.new(first_name: 'Johnny', last_name: nil, gender: 'male', start_time: "2015-07-01 06:00:00")
    expect(effort).not_to be_valid
    expect(effort.errors[:last_name]).to include("can't be blank")
  end

  it "should be invalid without a gender" do
    effort = Effort.new(first_name: 'Johnny', last_name: 'Appleseed', gender: nil, start_time: "2015-07-01 06:00:00")
    expect(effort).not_to be_valid
    expect(effort.errors[:gender]).to include("can't be blank")
  end

  it "should be invalid without a start time" do
    effort = Effort.new(event_id: 1, first_name: 'David', last_name: 'Goliath', gender: 'male', start_time: nil)
    expect(effort).not_to be_valid
    expect(effort.errors[:start_time]).to include("can't be blank")
  end

  it "should not permit more than one effort by a participant in a given event" do
    Effort.create!(event_id: 1, first_name: 'David', last_name: 'Goliath', gender: 'male', participant_id: 1, start_time: "2015-07-01 06:00:00")
    effort = Effort.new(event_id: 1, first_name: 'David', last_name: 'Goliath', gender: 'male', participant_id: 1, start_time: "2015-07-01 06:00:00")
    expect(effort).not_to be_valid
    expect(effort.errors[:participant_id]).to include("has already been taken")
  end

  it "should not permit duplicate bib_numbers within a given event" do
    Effort.create!(event_id: 1, first_name: 'David', last_name: 'Goliath', gender: 'male', bib_number: 20, start_time: "2015-07-01 06:00:00")
    effort = Effort.new(event_id: 1, participant_id: 2, bib_number: 20, start_time: "2015-07-01 06:00:00")
    expect(effort).not_to be_valid
    expect(effort.errors[:bib_number]).to include("has already been taken")
  end

end