require "rails_helper"

# t.integer  "course_id"
# t.integer  "race_id"
# t.string   "name"
# t.datetime "first_start_time"

RSpec.describe Event, type: :model do
  it "should be valid when created with a course, a name, and a start time" do
    course = Course.create!(name: 'Slo Mo 100 CCW')
    event = Event.create!(course_id: course.id, name: 'Slo Mo 100 2015', first_start_time: "2015-07-01 06:00:00")

    expect(Event.all.count).to eq(1)
    expect(event.course_id).to eq(course.id)
    expect(event.name).to eq('Slo Mo 100 2015')
    expect(event.first_start_time).to eq("2015-07-01 06:00:00".in_time_zone)
    expect(event).to be_valid
  end

  it "should be invalid without a course_id" do
    event = Event.new(course_id: nil, name: 'Slo Mo 100 2015', first_start_time: "2015-07-01")
    expect(event).not_to be_valid
    expect(event.errors[:course_id]).to include("can't be blank")
  end

  it "should be invalid without a name" do
    course = Course.create!(name: 'Slo Mo 100 CCW')
    event = Event.new(course_id: course.id, name: nil, first_start_time: "2015-07-01")
    expect(event).not_to be_valid
    expect(event.errors[:name]).to include("can't be blank")
  end

  it "should be invalid without a start date" do
    course = Course.create!(name: 'Slo Mo 100 CCW')
    event = Event.new(course_id: course.id, name: 'Slo Mo 100 2015', first_start_time: nil)
    expect(event).not_to be_valid
    expect(event.errors[:first_start_time]).to include("can't be blank")
  end

  it "should not allow for duplicate names" do
    course1 = Course.create!(name: 'Slo Mo 100 CW')
    course2 = Course.create!(name: 'Slo Mo 100 CCW')
    Event.create!(course_id: course1.id, name: 'Slo Mo 100 2015', first_start_time: "2015-07-01")
    event = Event.new(course_id: course2.id, name: 'Slo Mo 100 2015', first_start_time: "2016-07-01")
    expect(event).not_to be_valid
    expect(event.errors[:name]).to include("has already been taken")
  end

  describe 'waypoint_groups' do
    let(:course) { Course.create!(name: 'split test') }
    let(:event) { Event.create!(name: 'Waypoint Event', course: course, first_start_time: Time.current) }

    before do
      Split.create!(course: course, events: [event], location_id: 1, name: 'Start Point', distance_from_start: 0, sub_order: 0, kind: :start)
      Split.create!(course: course, events: [event], location_id: 2, name: 'Monarch Pass In', distance_from_start: 5000, sub_order: 0, kind: :waypoint)
      Split.create!(course: course, events: [event], location_id: 2, name: 'Monarch Pass Out', distance_from_start: 5000, sub_order: 1, kind: :waypoint)
      Split.create!(course: course, events: [event], location_id: 3, name: 'Halfway House In', distance_from_start: 25000, sub_order: 0, kind: :waypoint)
      Split.create!(course: course, events: [event], location_id: 3, name: 'Halfway House Out', distance_from_start: 25000, sub_order: 1, kind: :waypoint)
      Split.create!(course: course, events: [event], location_id: 7, name: 'Finish Point', distance_from_start: 50000, sub_order: 0, kind: :finish)
    end

    it 'should return a list of split ids for each of the waypoints grouped by distance' do
      expect(event.waypoint_groups.count).to eq(4)
      expect(event.waypoint_groups[0].count).to eq(1)
      expect(event.waypoint_groups[1].count).to eq(2)
      expect(event.waypoint_groups[2].count).to eq(2)
      expect(event.waypoint_groups[3].count).to eq(1)
    end
  end

end