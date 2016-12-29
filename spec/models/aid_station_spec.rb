require 'rails_helper'

# t.integer  "event_id"
# t.integer  "split_id"

RSpec.describe AidStation, type: :model do
    let(:course) { FactoryGirl.build_stubbed(:course) }
    let(:event) { FactoryGirl.build_stubbed(:event, course: course, name: 'Test Event', start_time: '2012-08-08 05:00:00') }
    let(:split) { FactoryGirl.build_stubbed(:split, course: course, base_name: 'Hopeless Outbound', distance_from_start: 50000) }
    let(:wrong_course) { FactoryGirl.build_stubbed(:course, name: 'Wrong Course') }
    let(:wrong_event) { FactoryGirl.build_stubbed(:event, course: wrong_course, name: 'Wrong Event', start_time: '2012-08-08 05:00:00') }
    let(:wrong_split) { FactoryGirl.build_stubbed(:split, course: wrong_course, base_name: 'Wrong Outbound', distance_from_start: 50000) }

  it 'should be valid with an event and a split' do
    aid_station = AidStation.new(event: event, split: split)
    expect(aid_station).to be_valid
  end

  it 'should be invalid without an event' do
    aid_station = AidStation.new(split: split)
    expect(aid_station).not_to be_valid
    expect(aid_station.errors[:event_id]).to include("can't be blank")
  end

  it 'should be invalid without a split' do
    aid_station = AidStation.new(event: event)
    expect(aid_station).not_to be_valid
    expect(aid_station.errors[:split_id]).to include("can't be blank")
  end

  it 'should be invalid if event course and split course are inconsistent' do
    aid_station = AidStation.new(event: event, split: wrong_split)
    expect(aid_station).not_to be_valid
    expect(aid_station.errors[:split_id]).to include("event's course is not the same as split's course")
    expect(aid_station.errors[:event_id]).to include("event's course is not the same as split's course")
  end

end
