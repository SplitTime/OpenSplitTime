require "rails_helper"

# t.integer  "effort_id"
# t.integer  "split_id"
# t.float    "time_from_start" (stored as seconds.milliseconds elapsed)
# t.integer  "data_status"

RSpec.describe SplitTime, kind: :model do
  
  before :each do
    @course = Course.create!(name: 'Test Course')
    @event = Event.create!(course: @course, name: 'Test Event 2015', first_start_time: "2015-07-01 06:00:00")
    @effort = Effort.create!(event: @event, first_name: 'David', last_name: 'Goliath', gender: 'male', start_offset: 0)
    @location1 = Location.create(name: 'Mountain Town', elevation: 2400, latitude: 40.1, longitude: -105)
    @location2 = Location.create(name: 'Mountain Hideout', elevation: 2900, latitude: 40.3, longitude: -105.05)
    @location3 = Location.create(name: 'Mountain Getaway', elevation: 2950, latitude: 40.3, longitude: -105.15)
    @split = Split.create!(course: @course, location: @location1, name: 'Hopeless Outbound In', distance_from_start: 50000, kind: 2)

  end
  it "should be valid when created with an effort, a split, and a time_from_start" do
    SplitTime.create!(effort: @effort, split: @split, time_from_start: 30000)

    expect(SplitTime.all.count).to eq(1)
    expect(SplitTime.first.effort).to eq(@effort)
    expect(SplitTime.first.split).to eq(@split)
    expect(SplitTime.first.time_from_start).to eq(30000)
  end

  it "should be invalid without an effort" do
    split = Split.create!(course: @course, location: @location1, name: 'Race Start', distance_from_start: 0, kind: 0)
    split_time = SplitTime.new(effort: nil, split: split, time_from_start: 0)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:effort_id]).to include("can't be blank")
  end

  it "should be invalid without a split_id" do
    split = Split.new(course: @course, location: @location1, name: 'Race Start', distance_from_start: 0, kind: 0)
    split_time = SplitTime.new(effort: @effort, split: split, time_from_start: 0)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:split_id]).to include("can't be blank")
  end

  it "should be invalid without a time_from_start" do
    split = Split.create!(course: @course, location: @location1, name: 'Race Start', distance_from_start: 0, kind: 0)
    split_time = SplitTime.new(effort: @effort, split: split, time_from_start: nil)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:time_from_start]).to include("can't be blank")
  end

  it "should not allow more than one of a given split_id within an effort" do
    split = Split.create!(course: @course, location: @location1, name: 'Aid Station', distance_from_start: 10000, kind: 2)
    SplitTime.create!(effort: @effort, split: split, time_from_start: 10000)
    split_time = SplitTime.new(effort: @effort, split: split, time_from_start: 11000)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:split_id]).to include("only one of any given split permitted within an effort")
  end

  it "should allow multiple of any given split_id within different efforts" do
    split = Split.create!(course: @course, location: @location1, name: 'Race Start', distance_from_start: 10000, kind: 2)
    effort2 = Effort.create!(event: @event, first_name: 'Jane', last_name: 'Eyre', gender: 'female', start_offset: 0)
    effort3 = Effort.create!(event: @event, first_name: 'Jane', last_name: 'of the Jungle', gender: 'female', start_offset: 0)
    effort4 = Effort.create!(event: @event, first_name: 'George', last_name: 'of the Jungle', gender: 'male', start_offset: 0)
    SplitTime.create!(effort: @effort, split: split, time_from_start: 10000)
    split_time1 = SplitTime.new(effort: effort2, split: split, time_from_start: 11000)
    split_time2 = SplitTime.new(effort: effort3, split: split, time_from_start: 12000)
    split_time3 = SplitTime.new(effort: effort4, split: split, time_from_start: 13000)
    expect(split_time1).to be_valid
    expect(split_time2).to be_valid
    expect(split_time3).to be_valid
  end

  it "should ensure that effort.event.course_id is the same as split.course_id" do
    course1 = Course.create!(name: 'Race Course CW')
    course2 = Course.create!(name: 'Hiking Course CCW')
    event = Event.create!(course: course1, name: 'Fast Times 100 2015', first_start_time: "2015-07-01 06:00:00")
    effort = Effort.create!(event: event, first_name: 'David', last_name: 'Goliath', gender: 'male')
    split = Split.create!(course: course2, location: @location1, name: 'Hiking Aid 1', distance_from_start: 50000, kind: 2)
    split_time = SplitTime.new(effort: effort, split: split, time_from_start: 30000)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:effort_id]).to include("the effort.event.course_id does not resolve with the split.course_id")
    expect(split_time.errors[:split_id]).to include("the effort.event.course_id does not resolve with the split.course_id")
  end

end