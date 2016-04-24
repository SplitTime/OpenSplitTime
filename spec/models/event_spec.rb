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
      event.splits.create!(course: course, name: 'Start Point', distance_from_start: 0, sub_order: 0, kind: :start)
      event.splits.create!(course: course, name: 'Monarch Pass In', distance_from_start: 5000, sub_order: 0, kind: :waypoint)
      event.splits.create!(course: course, name: 'Monarch Pass Out', distance_from_start: 5000, sub_order: 1, kind: :waypoint)
      event.splits.create!(course: course, name: 'Halfway House In', distance_from_start: 25000, sub_order: 0, kind: :waypoint)
      event.splits.create!(course: course, name: 'Halfway House Out', distance_from_start: 25000, sub_order: 1, kind: :waypoint)
      event.splits.create!(course: course, name: 'Finish Point', distance_from_start: 50000, sub_order: 0, kind: :finish)
    end

    it 'should return a list of split ids for each of the waypoints grouped by distance' do
      expect(event.waypoint_groups.count).to eq(4)
      expect(event.waypoint_groups[0].count).to eq(1)
      expect(event.waypoint_groups[1].count).to eq(2)
      expect(event.waypoint_groups[2].count).to eq(2)
      expect(event.waypoint_groups[3].count).to eq(1)
    end
  end

  describe 'waypoint_group' do
    let(:course) { Course.create!(name: 'split test') }
    let(:event) { Event.create!(name: 'Waypoint Event', course: course, first_start_time: Time.current) }

    before do
      event.splits.create!(course: course, name: 'Start Point', distance_from_start: 0, sub_order: 0, kind: :start)
      event.splits.create!(course: course, name: 'Monarch Pass In', distance_from_start: 5000, sub_order: 0, kind: :waypoint)
      event.splits.create!(course: course, name: 'Monarch Pass Out', distance_from_start: 5000, sub_order: 1, kind: :waypoint)
      event.splits.create!(course: course, name: 'Halfway House In', distance_from_start: 25000, sub_order: 0, kind: :waypoint)
      event.splits.create!(course: course, name: 'Halfway House Out', distance_from_start: 25000, sub_order: 1, kind: :waypoint)
      event.splits.create!(course: course, name: 'Finish Point', distance_from_start: 50000, sub_order: 0, kind: :finish)
    end

    it 'should return splits in the same distance group as the provided split' do
      split2 = event.splits.where(name: 'Monarch Pass In').first
      split3 = event.splits.where(name: 'Monarch Pass Out').first
      split6 = event.splits.where(name: 'Finish Point').first
      expect(event.waypoint_group(split2)).to eq([split2, split3])
      expect(event.waypoint_group(split6)).to eq([split6])
    end
  end

  describe 'segment_distance' do
    let(:course) { Course.create!(name: 'split test') }
    let(:event) { Event.create!(name: 'Waypoint Event', course: course, first_start_time: Time.current) }

    before do
      DatabaseCleaner.clean
      event.splits.create!(course: course, name: 'Start Point', distance_from_start: 0, sub_order: 0, kind: :start)
      event.splits.create!(course: course, name: 'Monarch Pass In', distance_from_start: 5000, sub_order: 0, kind: :waypoint)
      event.splits.create!(course: course, name: 'Monarch Pass Out', distance_from_start: 5000, sub_order: 1, kind: :waypoint)
      event.splits.create!(course: course, name: 'Halfway House In', distance_from_start: 25000, sub_order: 0, kind: :waypoint)
      event.splits.create!(course: course, name: 'Halfway House Out', distance_from_start: 25000, sub_order: 1, kind: :waypoint)
      event.splits.create!(course: course, name: 'Finish Point', distance_from_start: 50000, sub_order: 0, kind: :finish)
    end

    it 'should return the distance between splits when provided two parameters' do
      split1 = event.splits.find(1)
      split2 = event.splits.find(2)
      split3 = event.splits.find(3)
      split4 = event.splits.find(4)
      split5 = event.splits.find(5)
      expect(event.segment_distance(split3, split4)).to eq(20000)
      expect(event.segment_distance(split4, split5)).to eq(0)
      expect(event.segment_distance(split2, split1)).to eq(-5000)
    end

    it 'should return the distance between the provided split and the previous split when provided one parameter' do
      split2 = event.splits.find(2)
      split4 = event.splits.find(4)
      split5 = event.splits.find(5)
      expect(event.segment_distance(split4)).to eq(20000)
      expect(event.segment_distance(split5)).to eq(0)
      expect(event.segment_distance(split2)).to eq(5000)
    end

    it 'should return zero when provided one parameter that is a start split' do
      split1 = event.splits.find(1)
      expect(event.segment_distance(split1)).to eq(0)
    end
  end

  describe 'base_splits' do
    let(:course) { Course.create!(name: 'split test') }
    let(:event) { Event.create!(name: 'Waypoint Event', course: course, first_start_time: Time.current) }

    before do
      DatabaseCleaner.clean
      event.splits.create!(course: course, name: 'Start Point', distance_from_start: 0, sub_order: 0, kind: :start)
      event.splits.create!(course: course, name: 'Monarch Pass In', distance_from_start: 5000, sub_order: 0, kind: :waypoint)
      event.splits.create!(course: course, name: 'Monarch Pass Out', distance_from_start: 5000, sub_order: 1, kind: :waypoint)
      event.splits.create!(course: course, name: 'Halfway House In', distance_from_start: 25000, sub_order: 0, kind: :waypoint)
      event.splits.create!(course: course, name: 'Halfway House Out', distance_from_start: 25000, sub_order: 1, kind: :waypoint)
      event.splits.create!(course: course, name: 'Finish Point', distance_from_start: 50000, sub_order: 0, kind: :finish)
    end

    it 'should return all splits having sub_order == 0' do
      expect(event.base_splits.pluck(:id)).to eq([1,2,4,6])
    end
  end

end

