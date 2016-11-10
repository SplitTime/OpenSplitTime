require 'rails_helper'

# t.integer  "course_id"
# t.integer  "race_id"
# t.string   "name"
# t.datetime "start_time"

RSpec.describe Event, type: :model do
  it { is_expected.to strip_attribute(:name).collapse_spaces }
  let(:course) { Course.create!(name: 'Slo Mo 100 CCW') }
  let(:course2) { Course.create!(name: 'Slo Mo 100 CW') }

  it 'should be valid when created with a course, a name, and a start time' do
    event = Event.create!(course: course, name: 'Slo Mo 100 2015', start_time: '2015-07-01 06:00:00')

    expect(Event.all.count).to eq(1)
    expect(event.course).to eq(course)
    expect(event.name).to eq('Slo Mo 100 2015')
    expect(event.start_time).to eq('2015-07-01 06:00:00'.in_time_zone)
    expect(event).to be_valid
  end

  it 'should be invalid without a course' do
    event = Event.new(course: nil, name: 'Slo Mo 100 2015', start_time: '2015-07-01')
    expect(event).not_to be_valid
    expect(event.errors[:course_id]).to include("can't be blank")
  end

  it 'should be invalid without a name' do
    event = Event.new(course: course, name: nil, start_time: '2015-07-01')
    expect(event).not_to be_valid
    expect(event.errors[:name]).to include("can't be blank")
  end

  it 'should be invalid without a start date' do
    event = Event.new(course: course, name: 'Slo Mo 100 2015', start_time: nil)
    expect(event).not_to be_valid
    expect(event.errors[:start_time]).to include("can't be blank")
  end

  it 'should not allow for duplicate names' do
    Event.create!(course: course, name: 'Slo Mo 100 2015', start_time: '2015-07-01')
    event = Event.new(course: course2, name: 'Slo Mo 100 2015', start_time: '2016-07-01')
    expect(event).not_to be_valid
    expect(event.errors[:name]).to include('has already been taken')
  end
end