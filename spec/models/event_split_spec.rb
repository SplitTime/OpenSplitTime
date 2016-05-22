require 'rails_helper'

# t.integer  "event_id"
# t.integer  "split_id"

RSpec.describe EventSplit, type: :model do

  before :each do
    @course = Course.create!(name: 'Test Course')
    @event = Event.create!(course_id: @course.id, race_id: nil, name: 'Test Event', first_start_time: "2012-08-08 05:00:00")
    @split = Split.create!(course_id: @course.id,
                           base_name: 'Hopeless Outbound',
                           name_extension: 'In',
                           distance_from_start: 50000,
                           kind: 2)
  end

  it "should be valid with an event_id and a split_id" do
    event_split = EventSplit.create!(event_id: @event.id, split_id: @split.id)

    expect(EventSplit.all.count).to(equal(1))
    expect(event_split).to be_valid
  end

  it "should be invalid without an event_id" do
    event_split = EventSplit.new(event_id: nil, split_id: @split.id)
    expect(event_split).not_to be_valid
    expect(event_split.errors[:event_id]).to include("can't be blank")
  end

  it "should be invalid without a split_id" do
    event_split = EventSplit.new(event_id: @event.id, split_id: nil)
    expect(event_split).not_to be_valid
    expect(event_split.errors[:split_id]).to include("can't be blank")
  end

end
