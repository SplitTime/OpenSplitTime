require 'rails_helper'
require 'pry-byebug'

# t.integer  "event_id"
# t.integer  "participant_id"
# t.string   "wave"
# t.integer  "bib_number"
# t.string   "city"
# t.string   "state_code"
# t.string   "country_code"
# t.integer  "age"
# t.datetime "start_time"
# t.boolean  "dropped"

RSpec.describe Effort, type: :model do

  before :each do
    DatabaseCleaner.clean
    @course = Course.create!(name: 'Test Course')
    @event = Event.create!(course_id: @course.id, race_id: nil, name: 'Test Event', first_start_time: "2012-08-08 05:00:00")
    @location1 = Location.create!(name: 'Mountain Town', elevation: 2400, latitude: 40.1, longitude: -105)
    @location2 = Location.create!(name: 'Mountain Hideout', elevation: 2900, latitude: 40.3, longitude: -105.05)
    @participant = Participant.create!(first_name: 'Joe', last_name: 'Hardman',
                                       gender: 'male', birthdate: "1989-12-15",
                                       city: 'Boulder', state_code: 'CO', country_code: 'US')
  end

  it "should be valid when created with an event_id, first_name, last_name, gender, and start_time" do
    @event = Event.create!(course_id: @course.id, name: 'Hardrock 2015', first_start_time: "2015-07-01 06:00:00")
    Effort.create!(event_id: @event.id, first_name: 'David', last_name: 'Goliath', gender: 'male', start_time: @event.first_start_time)

    expect(Effort.all.count).to(equal(1))
    expect(Effort.first.event_id).to eq(@event.id)
    expect(Effort.first.last_name).to eq('Goliath')
  end

  it "should be invalid without an event_id" do
    effort = Effort.new(event_id: nil, first_name: 'David', last_name: 'Goliath', gender: 'male', start_time: "2015-07-01 06:00:00")
    expect(effort).not_to be_valid
    expect(effort.errors[:event_id]).to include("can't be blank")
  end

  it "should be invalid without a first_name" do
    effort = Effort.new(event_id: @event.id, first_name: nil, last_name: 'Appleseed', gender: 'male', start_time: "2015-07-01 06:00:00")
    expect(effort).not_to be_valid
    expect(effort.errors[:first_name]).to include("can't be blank")
  end

  it "should be invalid without a last_name" do
    effort = Effort.new(first_name: 'Johnny', last_name: nil, gender: 'male', start_time: "2015-07-01 06:00:00")
    expect(effort).not_to be_valid
    expect(effort.errors[:last_name]).to include("can't be blank")
  end

  it "should be invalid without a gender" do
    effort = Effort.new(first_name: 'Johnny', last_name: 'Appleseed', gender: nil, start_time: "2015-07-01 06:00:00")
    expect(effort).not_to be_valid
    expect(effort.errors[:gender]).to include("can't be blank")
  end

  it "should be invalid without a start time" do
    effort = Effort.new(event_id: @event.id, first_name: 'David', last_name: 'Goliath', gender: 'male', start_time: nil)
    expect(effort).not_to be_valid
    expect(effort.errors[:start_time]).to include("can't be blank")
  end

  it "should not permit more than one effort by a participant in a given event" do
    Effort.create!(event_id: @event.id, first_name: 'David', last_name: 'Goliath', gender: 'male',
                   participant_id: @participant.id, start_time: "2015-07-01 06:00:00")
    effort = Effort.new(event_id: @event.id, first_name: 'David', last_name: 'Goliath', gender: 'male',
                        participant_id: @participant.id, start_time: "2015-07-01 06:00:00")
    expect(effort).not_to be_valid
    expect(effort.errors[:participant_id]).to include("has already been taken")
  end

  it "should not permit duplicate bib_numbers within a given event" do
    Effort.create!(event_id: @event.id, first_name: 'David', last_name: 'Goliath', gender: 'male', bib_number: 20, start_time: "2015-07-01 06:00:00")
    effort = Effort.new(event_id: @event.id, participant_id: 2, bib_number: 20, start_time: "2015-07-01 06:00:00")
    expect(effort).not_to be_valid
    expect(effort.errors[:bib_number]).to include("has already been taken")
  end

  describe 'within_time_range' do
    before do

      DatabaseCleaner.clean
      course = Course.create!(name: 'Test Course 100')
      event = Event.create!(name: 'Test Event 2015', course_id: @course.id, first_start_time: "2015-07-01 06:00:00")
      location1 = Location.create!(name: 'Mountain Town', elevation: 2400, latitude: 40.1, longitude: -105)
      location2 = Location.create!(name: 'Mountain Hideout', elevation: 2900, latitude: 40.3, longitude: -105.05)

      effort1 = Effort.create!(event_id: event.id, bib_number: 99, city: 'Vancouver', state_code: 'BC', country_code: 'CA', age: 50, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      effort2 = Effort.create!(event_id: event.id, bib_number: 12, city: 'Boulder', state_code: 'CO', country_code: 'US', age: 23, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Joe', last_name: 'Hardman', gender: 'male')
      effort3 = Effort.create!(event_id: event.id, bib_number: 150, city: 'Nantucket', state_code: 'MA', country_code: 'US', age: 26, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Jane', last_name: 'Rockstar', gender: 'female')

      split1 = Split.create!(course_id: course.id, location_id: location1.id, name: 'Test Starting Line', distance_from_start: 0, vert_gain_from_start: 0, vert_loss_from_start: 0, kind: 0)
      split2 = Split.create!(course_id: course.id, location_id: location2.id, name: 'Test Aid Station In', distance_from_start: 6000, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      split3 = Split.create!(course_id: course.id, location_id: location2.id, name: 'Test Aid Station Out', distance_from_start: 6000, sub_order: 1, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      split4 = Split.create!(course_id: course.id, location_id: location1.id, name: 'Test Finish Line', distance_from_start: 10000, vert_gain_from_start: 700, vert_loss_from_start: 700, kind: 1)

      event.splits << course.splits

      SplitTime.create!(effort_id: effort1.id, split_id: split1.id, time_from_start: 0)
      SplitTime.create!(effort_id: effort1.id, split_id: split2.id, time_from_start: 4000)
      SplitTime.create!(effort_id: effort1.id, split_id: split3.id, time_from_start: 4100)
      SplitTime.create!(effort_id: effort1.id, split_id: split4.id, time_from_start: 8000)
      SplitTime.create!(effort_id: effort2.id, split_id: split1.id, time_from_start: 0)
      SplitTime.create!(effort_id: effort2.id, split_id: split2.id, time_from_start: 5000)
      SplitTime.create!(effort_id: effort2.id, split_id: split3.id, time_from_start: 5100)
      SplitTime.create!(effort_id: effort2.id, split_id: split4.id, time_from_start: 9000)
      SplitTime.create!(effort_id: effort3.id, split_id: split1.id, time_from_start: 0)
      SplitTime.create!(effort_id: effort3.id, split_id: split2.id, time_from_start: 3000)
      SplitTime.create!(effort_id: effort3.id, split_id: split3.id, time_from_start: 3100)
      SplitTime.create!(effort_id: effort3.id, split_id: split4.id, time_from_start: 7500)

    end

    it 'should return only those efforts for which the finish time is between the parameters provided' do
      efforts = Effort.all
      expect(efforts.within_time_range(7800,8200).count).to eq(1)
      expect(efforts.within_time_range(5000,10000).count).to eq(3)
      expect(efforts.within_time_range(10000,20000).count).to eq(0)
    end
  end

  describe 'segment_velocity' do
    before do

      DatabaseCleaner.clean
      @course = Course.create!(name: 'Test Course 100')
      @event = Event.create!(name: 'Test Event 2015', course_id: @course.id, first_start_time: "2015-07-01 06:00:00")

      @effort1 = Effort.create!(event_id: @event.id, bib_number: 99, city: 'Vancouver', state_code: 'BC', country_code: 'CA', age: 50, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      @effort2 = Effort.create!(event_id: @event.id, bib_number: 12, city: 'Boulder', state_code: 'CO', country_code: 'US', age: 23, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Joe', last_name: 'Hardman', gender: 'male')

      @split1 = Split.create!(course_id: @course.id, name: 'Test Starting Line', distance_from_start: 0, vert_gain_from_start: 0, vert_loss_from_start: 0, kind: 0)
      @split2 = Split.create!(course_id: @course.id, name: 'Test Aid Station In', distance_from_start: 6000, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split3 = Split.create!(course_id: @course.id, name: 'Test Aid Station Out', distance_from_start: 6000, sub_order: 1, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split4 = Split.create!(course_id: @course.id, name: 'Test Finish Line', distance_from_start: 10000, vert_gain_from_start: 700, vert_loss_from_start: 700, kind: 1)

      @event.splits << @course.splits

      SplitTime.create!(effort_id: @effort1.id, split_id: @split1.id, time_from_start: 0)
      SplitTime.create!(effort_id: @effort1.id, split_id: @split2.id, time_from_start: 4000)
      SplitTime.create!(effort_id: @effort1.id, split_id: @split3.id, time_from_start: 4100)
      SplitTime.create!(effort_id: @effort1.id, split_id: @split4.id, time_from_start: 8000)
      SplitTime.create!(effort_id: @effort2.id, split_id: @split1.id, time_from_start: 0)
      SplitTime.create!(effort_id: @effort2.id, split_id: @split2.id, time_from_start: 5000)
      SplitTime.create!(effort_id: @effort2.id, split_id: @split3.id, time_from_start: 5100)
      SplitTime.create!(effort_id: @effort2.id, split_id: @split4.id, time_from_start: 9000)

    end

    it 'should return velocity in m/s between any two provided splits' do
      expect(@effort1.segment_velocity(@split1, @split2)).to eq(6000 / 4000.0)
      expect(@effort2.segment_velocity(@split1, @split4)).to eq(10000 / 9000.0)
      expect(@effort1.segment_velocity(@split2, @split3)).to eq(0)
    end

    it 'should return velocity in m/s between a provided split and the previous split when only one split is provided' do
      expect(@effort1.segment_velocity(@split2)).to eq(6000 / 4000.0)
      expect(@effort2.segment_velocity(@split4)).to eq(4000 / 3900.0)
      expect(@effort1.segment_velocity(@split3)).to eq(0)
    end
  end

  describe 'set_time_data_status_best' do
    before do

      DatabaseCleaner.clean
      @course = Course.create!(name: 'Test Course 100')
      @event = Event.create!(name: 'Test Event 2015', course_id: @course.id, first_start_time: "2015-07-01 06:00:00")

      @effort1 = Effort.create!(event_id: @event.id, bib_number: 99, city: 'Vancouver', state_code: 'BC', country_code: 'CA', age: 50, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      @effort2 = Effort.create!(event_id: @event.id, bib_number: 12, city: 'Boulder', state_code: 'CO', country_code: 'US', age: 23, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Joe', last_name: 'Hardman', gender: 'male')

      @split1 = Split.create!(course_id: @course.id, name: 'Starting Line', distance_from_start: 0, vert_gain_from_start: 0, vert_loss_from_start: 0, kind: 0)
      @split2 = Split.create!(course_id: @course.id, name: 'Aid Station 1 In', distance_from_start: 6000, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split3 = Split.create!(course_id: @course.id, name: 'Aid Station 1 Out', distance_from_start: 6000, sub_order: 1, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split4 = Split.create!(course_id: @course.id, name: 'Aid Station 2 In', distance_from_start: 15000, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split5 = Split.create!(course_id: @course.id, name: 'Aid Station 2 Out', distance_from_start: 15000, sub_order: 1, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split6 = Split.create!(course_id: @course.id, name: 'Finish Line', distance_from_start: 25000, vert_gain_from_start: 700, vert_loss_from_start: 700, kind: 1)

      @event.splits << @course.splits

      @split_time1 = SplitTime.create!(effort_id: @effort1.id, split_id: @split1.id, time_from_start: 0)
      @split_time2 = SplitTime.create!(effort_id: @effort1.id, split_id: @split2.id, time_from_start: 4000)
      @split_time3 = SplitTime.create!(effort_id: @effort1.id, split_id: @split3.id, time_from_start: 4100)
      @split_time4 = SplitTime.create!(effort_id: @effort1.id, split_id: @split4.id, time_from_start: 15200)
      @split_time5 = SplitTime.create!(effort_id: @effort1.id, split_id: @split5.id, time_from_start: 15100)
      @split_time6 = SplitTime.create!(effort_id: @effort1.id, split_id: @split6.id, time_from_start: 21000)
      @split_time7 = SplitTime.create!(effort_id: @effort2.id, split_id: @split1.id, time_from_start: 0)
      @split_time8 = SplitTime.create!(effort_id: @effort2.id, split_id: @split2.id, time_from_start: 60)
      @split_time9 = SplitTime.create!(effort_id: @effort2.id, split_id: @split3.id, time_from_start: 120)
      @split_time10 = SplitTime.create!(effort_id: @effort2.id, split_id: @split4.id, time_from_start: 13000)
      @split_time11 = SplitTime.create!(effort_id: @effort2.id, split_id: @split5.id, time_from_start: 150000)
      @split_time12 = SplitTime.create!(effort_id: @effort2.id, split_id: @split6.id, time_from_start: 24000)

      @effort1.set_time_data_status_best
      @effort2.set_time_data_status_best

    end

    it 'should set the data status of negative segment times to bad' do
      expect(@split_time5.data_status).to eq('bad')
      expect(@split_time12.data_status).to eq('bad')
    end

    it 'should set the data status of impossibly fast segments to bad' do
      expect(@split_time8.data_status).to eq('bad')
      expect(@split_time12.data_status).to eq('bad')
    end

    it 'should set the data status of the instance effort to the lowest status of the split times' do
      expect(@effort1.data_status).to eq('bad')
      expect(@effort2.data_status).to eq('bad')
    end
  end

end