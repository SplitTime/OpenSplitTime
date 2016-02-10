require "rails_helper"

# t.integer  "effort_id"
# t.integer  "split_id"
# t.float    "time_from_start" (stored as seconds.milliseconds elapsed)
# t.integer  "data_status"

RSpec.describe SplitTime, kind: :model do
  it "should be valid when created with an effort_id, a split_id, and a time_from_start" do
    course = Course.create!(name: 'Test Course')
    event = Event.create!(course_id: course.id, name: 'Test Event 2015', start_date: "2015-07-01")
    effort = Effort.create!(event_id: event.id, participant_id: 1, start_time: "2015-07-01 06:00:00")
    split = Split.create!(course_id: course.id, location_id: 1, name: 'Hopeless Outbound In', distance_from_start: 50000, kind: 2)
    SplitTime.create!(effort_id: effort.id, split_id: split.id, time_from_start: 30000)

    expect(SplitTime.all.count).to eq(1)
    expect(SplitTime.first.effort_id).to eq(effort.id)
    expect(SplitTime.first.split_id).to eq(split.id)
    expect(SplitTime.first.time_from_start).to eq(30000)
  end

  it "should be invalid without an effort_id" do
    split = Split.create!(course_id: 1, location_id: 1, name: 'Race Start', distance_from_start: 0, kind: 0)
    split_time = SplitTime.new(effort_id: nil, split_id: split.id, time_from_start: 0)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:effort_id]).to include("can't be blank")
  end

  it "should be invalid without a split_id" do
    split = Split.new(course_id: 1, location_id: 1, name: 'Race Start', distance_from_start: 0, kind: 0)
    split_time = SplitTime.new(effort_id: 1, split_id: split.id, time_from_start: 0)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:split_id]).to include("can't be blank")
  end

  it "should be invalid without a time_from_start" do
    split = Split.create!(course_id: 1, location_id: 1, name: 'Race Start', distance_from_start: 0, kind: 0)
    split_time = SplitTime.new(effort_id: 1, split_id: split.id, time_from_start: nil)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:time_from_start]).to include("can't be blank")
  end

  it "should not allow more than one of a given split_id within an effort" do
    split = Split.create!(course_id: 1, location_id: 1, name: 'Aid Station', distance_from_start: 10000, kind: 2)
    SplitTime.create!(effort_id: 1, split_id: split.id, time_from_start: 10000)
    split_time = SplitTime.new(effort_id: 1, split_id: split.id, time_from_start: 11000)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:split_id]).to include("only one of any given split permitted within an effort")
  end

  it "should allow multiple of any given split_id within different efforts" do
    split = Split.create!(course_id: 1, location_id: 1, name: 'Race Start', distance_from_start: 10000, kind: 2)
    SplitTime.create!(effort_id: 1, split_id: split.id, time_from_start: 10000)
    split_time1 = SplitTime.new(effort_id: 2, split_id: split.id, time_from_start: 11000)
    split_time2 = SplitTime.new(effort_id: 3, split_id: split.id, time_from_start: 12000)
    split_time3 = SplitTime.new(effort_id: 4, split_id: split.id, time_from_start: 13000)
    expect(split_time1).to be_valid
    expect(split_time2).to be_valid
    expect(split_time3).to be_valid
  end

  it "should ensure that time_from_start is 0 when split_id references a start split" do
    split = Split.create!(course_id: 1, location_id: 1, name: 'Race Start', distance_from_start: 0, kind: 0)
    split_time = SplitTime.new(effort_id: 1, split_id: split.id, time_from_start: 100)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:time_from_start]).to include("the starting split_time must have 0 time from start")
  end

  it "should require time_from_start be positive when split_id references a waypoint split or a finish split" do
    split1 = Split.create!(course_id: 1, location_id: 2, name: 'Race Aid', distance_from_start: 10000, kind: 2)
    split2 = Split.create!(course_id: 1, location_id: 3, name: 'Race End', distance_from_start: 20000, kind: 1)
    split_time1 = SplitTime.new(effort_id: 1, split_id: split1.id, time_from_start: 0)
    split_time2 = SplitTime.new(effort_id: 1, split_id: split2.id, time_from_start: 0)
    expect(split_time1).not_to be_valid
    expect(split_time1.errors[:time_from_start]).to include("waypoint and finish split_times must have positive time from start")
    expect(split_time2).not_to be_valid
    expect(split_time2.errors[:time_from_start]).to include("waypoint and finish split_times must have positive time from start")
  end

  it "should ensure that effort.event.course_id is the same as split.course_id" do
    course1 = Course.create!(name: 'Race Course CW')
    course2 = Course.create!(name: 'Hiking Course CCW')
    event = Event.create!(course_id: course1.id, name: 'Fast Times 100 2015', start_date: "2015-07-01")
    effort = Effort.create!(event_id: event.id, participant_id: 1, start_time: "2015-07-01 06:00:00")
    split = Split.create!(course_id: course2.id, location_id: 1, name: 'Hiking Aid 1', distance_from_start: 50000, kind: 2)
    split_time = SplitTime.new(effort_id: effort.id, split_id: split.id, time_from_start: 30000)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:effort_id]).to include("the effort.event.course_id does not resolve with the split.course_id")
    expect(split_time.errors[:split_id]).to include("the effort.event.course_id does not resolve with the split.course_id")
  end

end