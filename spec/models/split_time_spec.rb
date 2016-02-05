require "rails_helper"

# t.integer  "effort_id"
# t.integer  "split_id"
# t.float    "time_from_start" (stored as seconds.milliseconds elapsed)
# t.integer  "data_status"

RSpec.describe SplitTime, kind: :model do
  it "should be valid when created with an effort_id, a split_id, and a time_from_start" do
    effort = Effort.create!(event_id: 1, participant_id: 1, start_time: "2015-07-01 06:00:00")
    split = Split.create!(course_id: 1, location_id: 1, name: 'Hopeless Outbound In', distance_from_start: 50000, kind: 2)
    SplitTime.create!(effort_id: effort.id, split_id: split.id, time_from_start: 30000)

    expect(SplitTime.all.count).to eq(1)
    expect(SplitTime.first.effort_id).to eq(effort.id)
    expect(SplitTime.first.split_id).to eq(split.id)
    expect(SplitTime.first.time_from_start).to eq(30000)
  end

  it "should be invalid without an effort_id" do
    split_time = SplitTime.new(effort_id: nil, split_id: 1, time_from_start: "10:00:00")
    split_time.valid?
    expect(split_time.errors[:effort_id]).to include("can't be blank")
  end

  it "should be invalid without a split_id" do
    split_time = SplitTime.new(effort_id: 1, split_id: nil, time_from_start: "10:00:00")
    split_time.valid?
    expect(split_time.errors[:split_id]).to include("can't be blank")
  end

  it "should be invalid without a time_from_start" do
    split_time = SplitTime.new(effort_id: 1, split_id: 1, time_from_start: nil)
    split_time.valid?
    expect(split_time.errors[:time_from_start]).to include("can't be blank")
  end

  it "should not allow more than one of a given split_id within an effort" do
    SplitTime.create!(effort_id: 1, split_id: 1, time_from_start: "10:00:00")
    split_time = SplitTime.new(effort_id: 1, split_id: 1, time_from_start: "11:00:00")
    split_time.valid?
    expect(split_time.errors[:split_id]).to include("only one of any given split permitted within an effort")
  end

  it "should allow multiple of any given split_id within different efforts" do
    SplitTime.create!(effort_id: 1, split_id: 1, time_from_start: "10:00:00")
    split_time1 = SplitTime.new(effort_id: 2, split_id: 1, time_from_start: "11:00:00")
    split_time2 = SplitTime.new(effort_id: 3, split_id: 1, time_from_start: "12:00:00")
    split_time3 = SplitTime.new(effort_id: 4, split_id: 1, time_from_start: "13:00:00")
    expect(split_time1).to be_valid
    expect(split_time2).to be_valid
    expect(split_time3).to be_valid
  end

end