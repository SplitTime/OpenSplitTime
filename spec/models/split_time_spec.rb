require 'rails_helper'

# t.integer  "effort_id"
# t.integer  "split_id"
# t.float    "time_from_start" (stored as seconds.milliseconds elapsed)
# t.integer  "data_status"
# t.integer  "sub_split_bitkey"

RSpec.describe SplitTime, kind: :model do
  let(:course) { Course.create!(name: 'Test Course') }
  let(:event) { Event.create!(course: course, name: 'Test Event 2015', start_time: '2015-07-01 06:00:00') }
  let(:effort) { Effort.create!(event: event, first_name: 'David', last_name: 'Goliath', gender: 'male', start_offset: 0) }
  let(:location1) { Location.create(name: 'Mountain Town', elevation: 2400, latitude: 40.1, longitude: -105) }
  let(:location2) { Location.create(name: 'Mountain Hideout', elevation: 2900, latitude: 40.3, longitude: -105.05) }
  let(:location3) { Location.create(name: 'Mountain Getaway', elevation: 2950, latitude: 40.3, longitude: -105.15) }
  let(:start_split) { Split.create!(course: course, location: location1, base_name: 'Start', sub_split_bitmap: 1, distance_from_start: 0, kind: 0) }
  let(:split) { Split.create!(course: course, location: location1, base_name: 'Hopeless Outbound', sub_split_bitmap: 3, distance_from_start: 50000, kind: 2) }

  it 'should be valid when created with an effort, a split, a sub_split, and a time_from_start' do
    SplitTime.create!(effort: effort, split: split, bitkey: SubSplit::IN_BITKEY, time_from_start: 30000)

    expect(SplitTime.all.count).to eq(1)
    expect(SplitTime.first.effort).to eq(effort)
    expect(SplitTime.first.split).to eq(split)
    expect(SplitTime.first.sub_split_bitkey).to eq(SubSplit::IN_BITKEY)
    expect(SplitTime.first.time_from_start).to eq(30000)
  end

  it 'should be invalid without an effort' do
    split_time = SplitTime.new(effort: nil, split: split, bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:effort_id]).to include("can't be blank")
  end

  it 'should be invalid without a split_id' do
    split_time = SplitTime.new(effort: effort, split: nil, bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:split_id]).to include("can't be blank")
  end

  it 'should be invalid without a sub_split_bitkey' do
    split_time = SplitTime.new(effort: effort, split: split, bitkey: nil, time_from_start: 0)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:sub_split_bitkey]).to include("can't be blank")
  end

  it 'should be invalid without a time_from_start' do
    split_time = SplitTime.new(effort: effort, split: split, bitkey: SubSplit::IN_BITKEY, time_from_start: nil)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:time_from_start]).to include("can't be blank")
  end

  it 'should not allow more than one of a given split_id/sub_split combination within an effort' do
    SplitTime.create!(effort: effort, split: split, bitkey: SubSplit::IN_BITKEY, time_from_start: 10000)
    split_time = SplitTime.new(effort: effort, split: split, bitkey: SubSplit::IN_BITKEY, time_from_start: 11000)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:split_id]).to include('only one of any given split/sub_split permitted within an effort')
  end

  it 'should allow within an effort one of a given split_id for each sub_split' do
    SplitTime.create!(effort: effort, split: split, bitkey: SubSplit::IN_BITKEY, time_from_start: 10000)
    split_time = SplitTime.new(effort: effort, split: split, bitkey: SubSplit::OUT_BITKEY, time_from_start: 11000)
    expect(split_time).to be_valid
  end

  it 'should allow multiple of a given split_id/sub_split combination within different efforts' do
    effort2 = Effort.create!(event: event, first_name: 'Jane', last_name: 'Eyre', gender: 'female', start_offset: 0)
    effort3 = Effort.create!(event: event, first_name: 'Jane', last_name: 'of the Jungle', gender: 'female', start_offset: 0)
    effort4 = Effort.create!(event: event, first_name: 'George', last_name: 'of the Jungle', gender: 'male', start_offset: 0)
    SplitTime.create!(effort: effort, split: split, bitkey: SubSplit::IN_BITKEY, time_from_start: 10000)
    split_time1 = SplitTime.new(effort: effort2, split: split, bitkey: SubSplit::IN_BITKEY, time_from_start: 11000)
    split_time2 = SplitTime.new(effort: effort3, split: split, bitkey: SubSplit::IN_BITKEY, time_from_start: 12000)
    split_time3 = SplitTime.new(effort: effort4, split: split, bitkey: SubSplit::IN_BITKEY, time_from_start: 13000)
    expect(split_time1).to be_valid
    expect(split_time2).to be_valid
    expect(split_time3).to be_valid
  end

  it 'should ensure that effort.event.course_id is the same as split.course_id' do
    course1 = Course.create!(name: 'Race Course CW')
    course2 = Course.create!(name: 'Hiking Course CCW')
    event = Event.create!(course: course1, name: 'Fast Times 100 2015', start_time: "2015-07-01 06:00:00")
    effort = Effort.create!(event: event, first_name: 'David', last_name: 'Goliath', gender: 'male')
    split = Split.create!(course: course2, location: location1, base_name: 'Hiking Aid 1', distance_from_start: 50000, kind: 2)
    split_time = SplitTime.new(effort: effort, split: split, time_from_start: 30000)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:effort_id]).to include('the effort.event.course_id does not resolve with the split.course_id')
    expect(split_time.errors[:split_id]).to include('the effort.event.course_id does not resolve with the split.course_id')
  end

  describe 'elapsed time' do
    it 'should return nil when time_from_start is nil' do
      split_time = SplitTime.new(effort: effort, split: split, time_from_start: nil)
      expect(split_time.elapsed_time).to be_nil
    end

    it 'should return time in hh:mm:ss format when time_from_start is present' do
      split_time = SplitTime.new(effort: effort, split: split, time_from_start: 4530)
      expect(split_time.elapsed_time).to eq('01:15:30')
    end

    it 'should return time in hh:mm:ss format when time_from_start is less than one hour' do
      split_time = SplitTime.new(effort: effort, split: split, time_from_start: 950)
      expect(split_time.elapsed_time).to eq('00:15:50')
    end

    it 'should return time in hh:mm:ss format when time_from_start is less than one minute' do
      split_time = SplitTime.new(effort: effort, split: split, time_from_start: 45)
      expect(split_time.elapsed_time).to eq('00:00:45')
    end

    it 'should return time in hh:mm:ss format when time_from_start is greater than 24 hours' do
      split_time = SplitTime.new(effort: effort, split: split, time_from_start: 100000)
      expect(split_time.elapsed_time).to eq('27:46:40')
    end

    it 'should return time in hh:mm:ss format when time_from_start is greater than 100 hours' do
      split_time = SplitTime.new(effort: effort, split: split, time_from_start: 500000)
      expect(split_time.elapsed_time).to eq('138:53:20')
    end
  end

  describe 'elapsed_time=' do
    it 'should remove an existing time_from_start when passed a nil value' do
      split_time = SplitTime.new(effort: effort, split: split, time_from_start: 100000)
      split_time.elapsed_time = nil
      expect(split_time.time_from_start).to be_nil
    end

    it 'should remove an existing time_from_start when passed an empty string' do
      split_time = SplitTime.new(effort: effort, split: split, time_from_start: 100000)
      split_time.elapsed_time = ''
      expect(split_time.time_from_start).to be_nil
    end

    it 'should set time_from_start properly when passed a string representing less than one minute' do
      split_time = SplitTime.new(effort: effort, split: split)
      split_time.elapsed_time = '00:00:25'
      expect(split_time.time_from_start).to eq(25)
    end

    it 'should set time_from_start properly when passed a string representing less than one hour' do
      split_time = SplitTime.new(effort: effort, split: split)
      split_time.elapsed_time = '00:30:25'
      expect(split_time.time_from_start).to eq(1825)
    end

    it 'should set time_from_start properly when passed a string representing more than one hour' do
      split_time = SplitTime.new(effort: effort, split: split)
      split_time.elapsed_time = '01:15:25'
      expect(split_time.time_from_start).to eq(4525)
    end

    it 'should set time_from_start properly when passed a string representing more than 24 hours' do
      split_time = SplitTime.new(effort: effort, split: split)
      split_time.elapsed_time = '27:46:45'
      expect(split_time.time_from_start).to eq(100005)
    end

    it 'should set time_from_start properly when passed a string representing more than 100 hours' do
      split_time = SplitTime.new(effort: effort, split: split)
      split_time.elapsed_time = '138:53:25'
      expect(split_time.time_from_start).to eq(500005)
    end
  end

  describe 'day_and_time' do
    it 'should return nil when time_from_start is nil' do
      split_time = SplitTime.new(effort: effort, split: split)
      expect(split_time.day_and_time).to be_nil
    end

    it 'should return a day and time equal to event start_time if time_from_start and start_offset are zero' do
      split_time = SplitTime.new(effort: effort, split: split, bitkey: 1, time_from_start: 0)
      expect(split_time.day_and_time).to eq(effort.start_time)
    end

    it 'should return a day and time equal to event start_time plus time_from_start when start_offset is zero' do
      split_time = SplitTime.new(effort: effort, split: split, bitkey: 1, time_from_start: 3600)
      expect(split_time.day_and_time).to eq(effort.start_time + 1.hour)
    end

    it 'should return correct day and time when time_from_start is greater than 24 hours' do
      split_time = SplitTime.new(effort: effort, split: split, bitkey: 1, time_from_start: 100000)
      expect(split_time.day_and_time).to eq(effort.start_time + 27.hours + 46.minutes + 40.seconds)
    end

    it 'should return correct day and time when time_from_start is greater than 100 hours' do
      split_time = SplitTime.new(effort: effort, split: split, bitkey: 1, time_from_start: 500000)
      expect(split_time.day_and_time).to eq(effort.start_time + 138.hours + 53.minutes + 20.seconds)
    end

    it 'should return correct day and time when start_offset is greater than zero' do
      effort1 = Effort.create!(event: event, first_name: 'David', last_name: 'Goliath', gender: 'male', start_offset: 3600)
      split_time = SplitTime.new(effort: effort1, split: split, bitkey: 1, time_from_start: 7200)
      expect(split_time.day_and_time).to eq(effort.start_time + 3.hours)
    end

    it 'should return correct day and time when start_offset is less than zero' do
      effort1 = Effort.create!(event: event, first_name: 'David', last_name: 'Goliath', gender: 'male', start_offset: -3600)
      split_time = SplitTime.new(effort: effort1, split: split, bitkey: 1, time_from_start: 7200)
      expect(split_time.day_and_time).to eq(effort.start_time + 1.hour)
    end
  end

  describe 'day_and_time=' do
    it 'should set time_from_start to nil if passed a nil value' do
      split_time = SplitTime.new(effort: effort, split: split, bitkey: 1, time_from_start: 1000)
      split_time.day_and_time = nil
      expect(split_time.time_from_start).to be_nil
    end

    it 'should set time_from_start to zero if passed the event start_time when start_offset is zero' do
      split_time = SplitTime.new(effort: effort, split: split, bitkey: 1)
      split_time.day_and_time = event.start_time
      expect(split_time.time_from_start).to eq(0)
    end

    it 'should set time_from_start to zero if passed the event start_time plus the effort start offset' do
      effort1 = Effort.create!(event: event, first_name: 'David', last_name: 'Goliath', gender: 'male', start_offset: 3600)
      split_time = SplitTime.new(effort: effort1, split: split, bitkey: 1)
      split_time.day_and_time = event.start_time + 3600
      expect(split_time.time_from_start).to eq(0)
    end

    it 'should set time_from_start properly if passed a TimeInZone object' do
      effort1 = Effort.create!(event: event, first_name: 'David', last_name: 'Goliath', gender: 'male', start_offset: 0)
      split_time = SplitTime.new(effort: effort1, split: split, bitkey: 1)
      split_time.day_and_time = Time.new(2015, 7, 1, 15, 0, 0).in_time_zone
      expect(split_time.time_from_start).to eq(9.hours)
    end

    it 'should set time_from_start properly if passed a TimeInZone object that is more than 24 hours ahead' do
      effort1 = Effort.create!(event: event, first_name: 'David', last_name: 'Goliath', gender: 'male', start_offset: 0)
      split_time = SplitTime.new(effort: effort1, split: split, bitkey: 1)
      split_time.day_and_time = Time.new(2015, 7, 2, 15, 0, 0).in_time_zone
      expect(split_time.time_from_start).to eq(33.hours)
    end

    it 'should set time_from_start properly if passed a TimeInZone object that is more than 100 hours ahead' do
      effort1 = Effort.create!(event: event, first_name: 'David', last_name: 'Goliath', gender: 'male', start_offset: 0)
      split_time = SplitTime.new(effort: effort1, split: split, bitkey: 1)
      split_time.day_and_time = Time.new(2015, 7, 5, 15, 0, 0).in_time_zone
      expect(split_time.time_from_start).to eq(105.hours)
    end

    it 'should set time_from_start properly if passed a TimeInZone object and adjust for positive start_offset' do
      effort1 = Effort.create!(event: event, first_name: 'David', last_name: 'Goliath', gender: 'male', start_offset: 1800)
      split_time = SplitTime.new(effort: effort1, split: split, bitkey: 1)
      split_time.day_and_time = Time.new(2015, 7, 1, 8, 0, 0).in_time_zone
      expect(split_time.time_from_start).to eq(90.minutes)
    end

    it 'should set time_from_start properly if passed a TimeInZone object and adjust for negative start_offset' do
      effort1 = Effort.create!(event: event, first_name: 'David', last_name: 'Goliath', gender: 'male', start_offset: -1800)
      split_time = SplitTime.new(effort: effort1, split: split, bitkey: 1)
      split_time.day_and_time = Time.new(2015, 7, 1, 8, 0, 0).in_time_zone
      expect(split_time.time_from_start).to eq(150.minutes)
    end
  end

  describe 'military time' do
    it 'should return nil if time_from_start is nil' do
      split_time = SplitTime.new(effort: effort, split: split)
      expect(split_time.military_time).to be_nil
    end

    it 'should return military time in hh:mm:ss format when time_from_start is present' do
      split_time = SplitTime.new(effort: effort, split: split, time_from_start: 0)
      expect(split_time.military_time).to eq('06:00:00')
    end

    it 'should return military time in hh:mm:ss format when time_from_start does not roll into following day' do
      split_time = SplitTime.new(effort: effort, split: split, time_from_start: 1800)
      expect(split_time.military_time).to eq('06:30:00')
    end

    it 'should return military time in hh:mm:ss format when result is in the hour before midnight' do
      split_time = SplitTime.new(effort: effort, split: split, time_from_start: 64740)
      expect(split_time.military_time).to eq('23:59:00')
    end

    it 'should return military time in hh:mm:ss format when result is in the hour after midnight' do
      split_time = SplitTime.new(effort: effort, split: split, time_from_start: 64860)
      expect(split_time.military_time).to eq('00:01:00')
    end

    it 'should return military time in hh:mm:ss format when time_from_start rolls into following day' do
      split_time = SplitTime.new(effort: effort, split: split, time_from_start: 72000)
      expect(split_time.military_time).to eq('02:00:00')
    end

    it 'should return military time in hh:mm:ss format when time_from_start rolls over multiple days' do
      split_time = SplitTime.new(effort: effort, split: split, time_from_start: 302400)
      expect(split_time.military_time).to eq('18:00:00')
    end

    it 'should properly account for a positive effort offset' do
      effort1 = Effort.create!(event: event, first_name: 'David', last_name: 'Goliath', gender: 'male', start_offset: 1800)
      split_time = SplitTime.new(effort: effort1, split: split, time_from_start: 1800)
      expect(split_time.military_time).to eq('07:00:00')
    end

    it 'should properly account for a negative effort offset' do
      effort1 = Effort.create!(event: event, first_name: 'David', last_name: 'Goliath', gender: 'male', start_offset: -1800)
      split_time = SplitTime.new(effort: effort1, split: split, time_from_start: 3600)
      expect(split_time.military_time).to eq('06:30:00')
    end
  end

  xdescribe 'military_time=' do
    it 'should set time_from_start to nil if passed a nil value' do
      split_time = SplitTime.new(effort: effort, split: split, bitkey: 1, time_from_start: 1000)
      split_time.military_time = nil
      expect(split_time.time_from_start).to be_nil
    end

    it 'should set time_from_start to nil if passed an empty string' do
      split_time = SplitTime.new(effort: effort, split: split, bitkey: 1, time_from_start: 1000)
      split_time.military_time = ''
      expect(split_time.time_from_start).to be_nil
    end

    it 'should detect the correct date and set time_from_start properly for a start split' do
      split_time = SplitTime.new(effort: effort, split: start_split, bitkey: 1)
      split_time.military_time = '06:05:00'
      expect(split_time.time_from_start).to eq(5.minutes)
    end

    it 'should detect the correct date and set time_from_start properly for an intermediate split' do
      split_time = SplitTime.new(effort: effort, split: split, bitkey: 1)
      split_time.military_time = '12:25:00'
      expect(split_time.time_from_start).to eq(6.hours + 25.minutes)
    end

    it 'should handle seconds properly' do
      split_time = SplitTime.new(effort: effort, split: split, bitkey: 1)
      split_time.military_time = '12:25:33'
      expect(split_time.time_from_start).to eq(6.hours + 25.minutes + 33.seconds)
    end

    it 'should handle hh:mm times properly' do
      split_time = SplitTime.new(effort: effort, split: split, bitkey: 1)
      split_time.military_time = '20:20'
      expect(split_time.time_from_start).to eq(14.hours + 20.minutes)
    end

    it 'should detect the correct date and set time_from_start properly when runner is ahead of schedule' do
      split_time = SplitTime.new(effort: effort, split: split, bitkey: 1)
      split_time.military_time = '09:25:00'
      expect(split_time.time_from_start).to eq(3.hours + 25.minutes)
    end

    it 'should detect the correct date and set time_from_start properly when runner is behind schedule' do
      split_time = SplitTime.new(effort: effort, split: split, bitkey: 1)
      split_time.military_time = '18:25:00'
      expect(split_time.time_from_start).to eq(12.hours + 25.minutes)
    end

    it 'should detect the correct date and set time_from_start properly when runner is into the following day' do
      split_time = SplitTime.new(effort: effort, split: split, bitkey: 1)
      split_time.military_time = '00:05:00'
      expect(split_time.time_from_start).to eq(18.hours + 5.minutes)
    end
  end
end