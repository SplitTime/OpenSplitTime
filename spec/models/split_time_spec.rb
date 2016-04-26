require "rails_helper"

# t.integer  "effort_id"
# t.integer  "split_id"
# t.float    "time_from_start" (stored as seconds.milliseconds elapsed)
# t.integer  "data_status"

RSpec.describe SplitTime, kind: :model do
  
  before :each do
    DatabaseCleaner.clean
    @course = Course.create!(name: 'Test Course')
    @event = Event.create!(course_id: @course.id, name: 'Test Event 2015', first_start_time: "2015-07-01 06:00:00")
    @effort = Effort.create!(event_id: @event.id, first_name: 'David', last_name: 'Goliath', gender: 'male', start_time: "2015-07-01 06:00:00")
    @location1 = Location.create(name: 'Mountain Town', elevation: 2400, latitude: 40.1, longitude: -105)
    @location2 = Location.create(name: 'Mountain Hideout', elevation: 2900, latitude: 40.3, longitude: -105.05)
    @location3 = Location.create(name: 'Mountain Getaway', elevation: 2950, latitude: 40.3, longitude: -105.15)
    @split = Split.create!(course_id: @course.id, location_id: @location1.id, name: 'Hopeless Outbound In', distance_from_start: 50000, kind: 2)

  end
  it "should be valid when created with an effort_id, a split_id, and a time_from_start" do
    SplitTime.create!(effort_id: @effort.id, split_id: @split.id, time_from_start: 30000)

    expect(SplitTime.all.count).to eq(1)
    expect(SplitTime.first.effort_id).to eq(@effort.id)
    expect(SplitTime.first.split_id).to eq(@split.id)
    expect(SplitTime.first.time_from_start).to eq(30000)
  end

  it "should be invalid without an effort_id" do
    split = Split.create!(course_id: 1, location_id: @location1.id, name: 'Race Start', distance_from_start: 0, kind: 0)
    split_time = SplitTime.new(effort_id: nil, split_id: split.id, time_from_start: 0)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:effort_id]).to include("can't be blank")
  end

  it "should be invalid without a split_id" do
    split = Split.new(course_id: 1, location_id: @location1.id, name: 'Race Start', distance_from_start: 0, kind: 0)
    split_time = SplitTime.new(effort_id: 1, split_id: split.id, time_from_start: 0)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:split_id]).to include("can't be blank")
  end

  it "should be invalid without a time_from_start" do
    split = Split.create!(course_id: 1, location_id: @location1.id, name: 'Race Start', distance_from_start: 0, kind: 0)
    split_time = SplitTime.new(effort_id: 1, split_id: split.id, time_from_start: nil)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:time_from_start]).to include("can't be blank")
  end

  it "should not allow more than one of a given split_id within an effort" do
    split = Split.create!(course_id: 1, location_id: @location1.id, name: 'Aid Station', distance_from_start: 10000, kind: 2)
    SplitTime.create!(effort_id: 1, split_id: split.id, time_from_start: 10000)
    split_time = SplitTime.new(effort_id: 1, split_id: split.id, time_from_start: 11000)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:split_id]).to include("only one of any given split permitted within an effort")
  end

  it "should allow multiple of any given split_id within different efforts" do
    split = Split.create!(course_id: 1, location_id: @location1.id, name: 'Race Start', distance_from_start: 10000, kind: 2)
    SplitTime.create!(effort_id: 1, split_id: split.id, time_from_start: 10000)
    split_time1 = SplitTime.new(effort_id: 2, split_id: split.id, time_from_start: 11000)
    split_time2 = SplitTime.new(effort_id: 3, split_id: split.id, time_from_start: 12000)
    split_time3 = SplitTime.new(effort_id: 4, split_id: split.id, time_from_start: 13000)
    expect(split_time1).to be_valid
    expect(split_time2).to be_valid
    expect(split_time3).to be_valid
  end

  it "should ensure that effort.event.course_id is the same as split.course_id" do
    course1 = Course.create!(name: 'Race Course CW')
    course2 = Course.create!(name: 'Hiking Course CCW')
    event = Event.create!(course_id: course1.id, name: 'Fast Times 100 2015', first_start_time: "2015-07-01 06:00:00")
    effort = Effort.create!(event_id: event.id, first_name: 'David', last_name: 'Goliath', gender: 'male', start_time: "2015-07-01 06:00:00")
    split = Split.create!(course_id: course2.id, location_id: @location1.id, name: 'Hiking Aid 1', distance_from_start: 50000, kind: 2)
    split_time = SplitTime.new(effort_id: effort.id, split_id: split.id, time_from_start: 30000)
    expect(split_time).not_to be_valid
    expect(split_time.errors[:effort_id]).to include("the effort.event.course_id does not resolve with the split.course_id")
    expect(split_time.errors[:split_id]).to include("the effort.event.course_id does not resolve with the split.course_id")
  end

  describe 'tfs_solo_data_status' do
    before do

      DatabaseCleaner.clean
      @course = Course.create!(name: 'Test Course 100')
      @event = Event.create!(name: 'Test Event 2015', course_id: @course.id, first_start_time: "2015-07-01 06:00:00")

      @effort1 = Effort.create!(event_id: @event.id, bib_number: 99, city: 'Vancouver', state_code: 'BC', country_code: 'CA', age: 50, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      @effort2 = Effort.create!(event_id: @event.id, bib_number: 12, city: 'Boulder', state_code: 'CO', country_code: 'US', age: 23, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Joe', last_name: 'Hardman', gender: 'male')
      @effort3 = Effort.create!(event_id: @event.id, bib_number: 20, city: 'Louisville', state_code: 'CO', country_code: 'US', age: 43, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Bill', last_name: 'Williams', gender: 'male')

      @split1 = Split.create!(course_id: @course.id, name: 'Test Starting Line', distance_from_start: 0, vert_gain_from_start: 0, vert_loss_from_start: 0, kind: 0)
      @split2 = Split.create!(course_id: @course.id, name: 'Test Aid Station In', distance_from_start: 6000, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split3 = Split.create!(course_id: @course.id, name: 'Test Aid Station Out', distance_from_start: 6000, sub_order: 1, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split4 = Split.create!(course_id: @course.id, name: 'Test Finish Line', distance_from_start: 10000, vert_gain_from_start: 700, vert_loss_from_start: 700, kind: 1)

      @event.splits << @course.splits

      @split_time1 = SplitTime.create!(effort_id: @effort1.id, split_id: @split1.id, time_from_start: 0)
      @split_time2 = SplitTime.create!(effort_id: @effort1.id, split_id: @split2.id, time_from_start: -100)
      @split_time3 = SplitTime.create!(effort_id: @effort1.id, split_id: @split3.id, time_from_start: 13000)
      @split_time4 = SplitTime.create!(effort_id: @effort1.id, split_id: @split4.id, time_from_start: 150000)
      @split_time5 = SplitTime.create!(effort_id: @effort2.id, split_id: @split1.id, time_from_start: 0)
      @split_time6 = SplitTime.create!(effort_id: @effort2.id, split_id: @split2.id, time_from_start: 5000)
      @split_time7 = SplitTime.create!(effort_id: @effort2.id, split_id: @split3.id, time_from_start: 5100)
      @split_time8 = SplitTime.create!(effort_id: @effort2.id, split_id: @split4.id, time_from_start: 9000)
      @split_time9 = SplitTime.create!(effort_id: @effort3.id, split_id: @split1.id, time_from_start: 100)
      @split_time10 = SplitTime.create!(effort_id: @effort3.id, split_id: @split2.id, time_from_start: 300)
      @split_time11 = SplitTime.create!(effort_id: @effort3.id, split_id: @split3.id, time_from_start: 350)
      @split_time12 = SplitTime.create!(effort_id: @effort3.id, split_id: @split4.id, time_from_start: 700)

    end

    it 'should return "bad" when time_from_start is negative' do
      expect(@split_time2.tfs_solo_data_status).to eq(0)
    end

    it 'should return "bad" or "questionable" as appropriate based on velocity' do
      expect(@split_time3.tfs_solo_data_status).to eq(1)
      expect(@split_time4.tfs_solo_data_status).to eq(0)
      expect(@split_time6.tfs_solo_data_status).to eq(nil)
      expect(@split_time7.tfs_solo_data_status).to eq(nil)
      expect(@split_time10.tfs_solo_data_status).to eq(0)
      expect(@split_time11.tfs_solo_data_status).to eq(0)
      expect(@split_time12.tfs_solo_data_status).to eq(1)
    end
  end

  describe 'st_data_status' do
    before do

      DatabaseCleaner.clean
      @course = Course.create!(name: 'Test Course 100')
      @event = Event.create!(name: 'Test Event 2015', course_id: @course.id, first_start_time: "2015-07-01 06:00:00")

      @effort1 = Effort.create!(event_id: @event.id, bib_number: 99, city: 'Vancouver', state_code: 'BC', country_code: 'CA', age: 50, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      @effort2 = Effort.create!(event_id: @event.id, bib_number: 12, city: 'Boulder', state_code: 'CO', country_code: 'US', age: 23, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Joe', last_name: 'Hardman', gender: 'male')
      @effort3 = Effort.create!(event_id: @event.id, bib_number: 20, city: 'Louisville', state_code: 'CO', country_code: 'US', age: 43, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Bill', last_name: 'Williams', gender: 'male')

      @split1 = Split.create!(course_id: @course.id, name: 'Test Starting Line', distance_from_start: 0, vert_gain_from_start: 0, vert_loss_from_start: 0, kind: 0)
      @split2 = Split.create!(course_id: @course.id, name: 'Test Aid Station In', distance_from_start: 6000, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split3 = Split.create!(course_id: @course.id, name: 'Test Aid Station Out', distance_from_start: 6000, sub_order: 1, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split4 = Split.create!(course_id: @course.id, name: 'Test Finish Line', distance_from_start: 10000, vert_gain_from_start: 700, vert_loss_from_start: 700, kind: 1)

      @event.splits << @course.splits

      @split_time1 = SplitTime.create!(effort_id: @effort1.id, split_id: @split1.id, time_from_start: 0)
      @split_time2 = SplitTime.create!(effort_id: @effort1.id, split_id: @split2.id, time_from_start: 13100)
      @split_time3 = SplitTime.create!(effort_id: @effort1.id, split_id: @split3.id, time_from_start: 15000000)
      @split_time4 = SplitTime.create!(effort_id: @effort1.id, split_id: @split4.id, time_from_start: 16000000)
      @split_time5 = SplitTime.create!(effort_id: @effort2.id, split_id: @split1.id, time_from_start: 0)
      @split_time6 = SplitTime.create!(effort_id: @effort2.id, split_id: @split2.id, time_from_start: 5000)
      @split_time7 = SplitTime.create!(effort_id: @effort2.id, split_id: @split3.id, time_from_start: 4900)
      @split_time8 = SplitTime.create!(effort_id: @effort2.id, split_id: @split4.id, time_from_start: 9000)
      @split_time9 = SplitTime.create!(effort_id: @effort3.id, split_id: @split1.id, time_from_start: 100)
      @split_time10 = SplitTime.create!(effort_id: @effort3.id, split_id: @split2.id, time_from_start: 300)
      @split_time11 = SplitTime.create!(effort_id: @effort3.id, split_id: @split3.id, time_from_start: 350)
      @split_time12 = SplitTime.create!(effort_id: @effort3.id, split_id: @split4.id, time_from_start: 700)

    end

    it 'should return "bad" when segment time is negative' do
      expect(@split_time7.st_data_status).to eq(0)
    end

    it 'for segments within a waypoint group, should return "bad" for excessively long periods' do
      expect(@split_time3.st_data_status).to eq(0)
    end

    it 'for segments not in a waypoint group, should return "bad" or "questionable" as appropriate based on segment velocity' do
      expect(@split_time2.st_data_status).to eq(1)
      expect(@split_time4.st_data_status).to eq(0)
      expect(@split_time6.st_data_status).to eq(nil)
      expect(@split_time8.st_data_status).to eq(nil)
      expect(@split_time10.st_data_status).to eq(0)
      expect(@split_time12.st_data_status).to eq(1)
    end
  end

end