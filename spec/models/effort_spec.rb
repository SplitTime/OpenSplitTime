require 'rails_helper'
require 'pry-byebug'

# t.integer  "event_id",                  null: false
# t.integer  "participant_id"
# t.string   "wave"
# t.integer  "bib_number"
# t.string   "city",           limit: 64
# t.string   "state_code",     limit: 64
# t.integer  "age"
# t.boolean  "dropped"
# t.string   "first_name"
# t.string   "last_name"
# t.integer  "gender"
# t.string   "country_code",   limit: 2
# t.date     "birthdate"
# t.integer  "data_status"
# t.integer  "start_offset"

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

  it "should be valid when created with an event_id, first_name, last_name, and gender" do
    @event = Event.create!(course_id: @course.id, name: 'Hardrock 2015', first_start_time: "2015-07-01 06:00:00")
    Effort.create!(event_id: @event.id, first_name: 'David', last_name: 'Goliath', gender: 'male')

    expect(Effort.all.count).to(equal(1))
    expect(Effort.first.event_id).to eq(@event.id)
    expect(Effort.first.last_name).to eq('Goliath')
  end

  it "should be invalid without an event_id" do
    effort = Effort.new(event_id: nil, first_name: 'David', last_name: 'Goliath', gender: 'male')
    expect(effort).not_to be_valid
    expect(effort.errors[:event_id]).to include("can't be blank")
  end

  it "should be invalid without a first_name" do
    effort = Effort.new(event_id: @event.id, first_name: nil, last_name: 'Appleseed', gender: 'male')
    expect(effort).not_to be_valid
    expect(effort.errors[:first_name]).to include("can't be blank")
  end

  it "should be invalid without a last_name" do
    effort = Effort.new(first_name: 'Johnny', last_name: nil, gender: 'male')
    expect(effort).not_to be_valid
    expect(effort.errors[:last_name]).to include("can't be blank")
  end

  it "should be invalid without a gender" do
    effort = Effort.new(first_name: 'Johnny', last_name: 'Appleseed', gender: nil)
    expect(effort).not_to be_valid
    expect(effort.errors[:gender]).to include("can't be blank")
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
      expect(@effort1.segment_velocity(Segment.new(@split1, @split2))).to eq(6000 / 4000.0)
      expect(@effort2.segment_velocity(Segment.new(@split1, @split4))).to eq(10000 / 9000.0)
      expect(@effort1.segment_velocity(Segment.new(@split2, @split3))).to eq(0)
    end

  end

  describe 'set_data_status' do
    before do

      DatabaseCleaner.clean
      @course = Course.create!(name: 'Test Course 100')
      @event = Event.create!(name: 'Test Event 2015', course_id: @course.id, first_start_time: "2015-07-01 06:00:00")

      @effort1 = Effort.create!(event_id: @event.id, bib_number: 1, city: 'Vancouver', state_code: 'BC', country_code: 'CA', age: 50, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      @effort2 = Effort.create!(event_id: @event.id, bib_number: 2, city: 'Boulder', state_code: 'CO', country_code: 'US', age: 23, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Joe', last_name: 'Hardman', gender: 'male')
      @effort3 = Effort.create!(event_id: @event.id, bib_number: 3, city: 'Denver', state_code: 'CO', country_code: 'US', age: 24, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Mark', last_name: 'Runner', gender: 'male')
      @effort4 = Effort.create!(event_id: @event.id, bib_number: 4, city: 'Louisville', state_code: 'CO', country_code: 'US', age: 25, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Pete', last_name: 'Trotter', gender: 'male')
      @effort5 = Effort.create!(event_id: @event.id, bib_number: 5, city: 'Fort Collins', state_code: 'CO', country_code: 'US', age: 26, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'James', last_name: 'Walker', gender: 'male')
      @effort6 = Effort.create!(event_id: @event.id, bib_number: 6, city: 'Colorado Springs', state_code: 'CO', country_code: 'US', age: 27, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Johnny', last_name: 'Hiker', gender: 'male')
      @effort7 = Effort.create!(event_id: @event.id, bib_number: 7, city: 'Idaho Springs', state_code: 'CO', country_code: 'US', age: 28, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Melissa', last_name: 'Getter', gender: 'female')
      @effort8 = Effort.create!(event_id: @event.id, bib_number: 8, city: 'Grand Junction', state_code: 'CO', country_code: 'US', age: 29, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'George', last_name: 'Ringer', gender: 'male')
      @effort9 = Effort.create!(event_id: @event.id, bib_number: 9, city: 'Aspen', state_code: 'CO', country_code: 'US', age: 30, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Abe', last_name: 'Goer', gender: 'male')
      @effort10 = Effort.create!(event_id: @event.id, bib_number: 10, city: 'Vail', state_code: 'CO', country_code: 'US', age: 31, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Tanya', last_name: 'Doer', gender: 'female')
      @effort11 = Effort.create!(event_id: @event.id, bib_number: 11, city: 'Frisco', state_code: 'CO', country_code: 'US', age: 32, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Sally', last_name: 'Tracker', gender: 'female')
      @effort12 = Effort.create!(event_id: @event.id, bib_number: 12, city: 'Glenwood Springs', state_code: 'CO', country_code: 'US', age: 32, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Linus', last_name: 'Peanut', gender: 'male')
      @effort13 = Effort.create!(event_id: @event.id, bib_number: 13, city: 'Limon', state_code: 'CO', country_code: 'US', age: 32, start_time: "2012-08-08 05:00:00", dropped: false, first_name: 'Lucy', last_name: 'Peanut', gender: 'female')

      @split1 = Split.create!(course_id: @course.id, name: 'Starting Line', distance_from_start: 0, vert_gain_from_start: 0, vert_loss_from_start: 0, kind: 0)
      @split2 = Split.create!(course_id: @course.id, name: 'Aid Station 1 In', distance_from_start: 6000, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split3 = Split.create!(course_id: @course.id, name: 'Aid Station 1 Out', distance_from_start: 6000, sub_order: 1, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split4 = Split.create!(course_id: @course.id, name: 'Aid Station 2 In', distance_from_start: 15000, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split5 = Split.create!(course_id: @course.id, name: 'Aid Station 2 Out', distance_from_start: 15000, sub_order: 1, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split6 = Split.create!(course_id: @course.id, name: 'Finish Line', distance_from_start: 25000, vert_gain_from_start: 700, vert_loss_from_start: 700, kind: 1)

      @event.splits << @course.splits

      SplitTime.create!(effort_id: @effort1.id, split_id: @split1.id, time_from_start: 0)
      SplitTime.create!(effort_id: @effort1.id, split_id: @split2.id, time_from_start: 4000)
      SplitTime.create!(effort_id: @effort1.id, split_id: @split3.id, time_from_start: 4100)
      SplitTime.create!(effort_id: @effort1.id, split_id: @split4.id, time_from_start: 15200)
      SplitTime.create!(effort_id: @effort1.id, split_id: @split5.id, time_from_start: 15100)
      SplitTime.create!(effort_id: @effort1.id, split_id: @split6.id, time_from_start: 21000)

      SplitTime.create!(effort_id: @effort2.id, split_id: @split1.id, time_from_start: 0)
      SplitTime.create!(effort_id: @effort2.id, split_id: @split2.id, time_from_start: 60)
      SplitTime.create!(effort_id: @effort2.id, split_id: @split3.id, time_from_start: 120)
      SplitTime.create!(effort_id: @effort2.id, split_id: @split4.id, time_from_start: 24000)
      SplitTime.create!(effort_id: @effort2.id, split_id: @split5.id, time_from_start: 150000)
      SplitTime.create!(effort_id: @effort2.id, split_id: @split6.id, time_from_start: 40000)

      SplitTime.create!(effort_id: @effort3.id, split_id: @split1.id, time_from_start: 0)
      SplitTime.create!(effort_id: @effort3.id, split_id: @split2.id, time_from_start: 5000)
      SplitTime.create!(effort_id: @effort3.id, split_id: @split3.id, time_from_start: 5000)
      SplitTime.create!(effort_id: @effort3.id, split_id: @split4.id, time_from_start: 12200)
      SplitTime.create!(effort_id: @effort3.id, split_id: @split5.id, time_from_start: 12300)
      SplitTime.create!(effort_id: @effort3.id, split_id: @split6.id, time_from_start: 18000)

      SplitTime.create!(effort_id: @effort4.id, split_id: @split1.id, time_from_start: 1000)
      SplitTime.create!(effort_id: @effort4.id, split_id: @split2.id, time_from_start: 4500)
      SplitTime.create!(effort_id: @effort4.id, split_id: @split3.id, time_from_start: 4400)
      SplitTime.create!(effort_id: @effort4.id, split_id: @split4.id, time_from_start: 11000)
      SplitTime.create!(effort_id: @effort4.id, split_id: @split5.id, time_from_start: 11000)
      SplitTime.create!(effort_id: @effort4.id, split_id: @split6.id, time_from_start: 17500)

      SplitTime.create!(effort_id: @effort5.id, split_id: @split1.id, time_from_start: 0)
      SplitTime.create!(effort_id: @effort5.id, split_id: @split2.id, time_from_start: 4600)
      SplitTime.create!(effort_id: @effort5.id, split_id: @split3.id, time_from_start: 4800)
      SplitTime.create!(effort_id: @effort5.id, split_id: @split4.id, time_from_start: 9800)
      SplitTime.create!(effort_id: @effort5.id, split_id: @split5.id, time_from_start: 10000)
      SplitTime.create!(effort_id: @effort5.id, split_id: @split6.id, time_from_start: 14550)

      SplitTime.create!(effort_id: @effort6.id, split_id: @split1.id, time_from_start: 0)
      SplitTime.create!(effort_id: @effort6.id, split_id: @split4.id, time_from_start: 9600)
      SplitTime.create!(effort_id: @effort6.id, split_id: @split5.id, time_from_start: 9660)
      SplitTime.create!(effort_id: @effort6.id, split_id: @split6.id, time_from_start: 14650)

      SplitTime.create!(effort_id: @effort7.id, split_id: @split1.id, time_from_start: 0)
      SplitTime.create!(effort_id: @effort7.id, split_id: @split2.id, time_from_start: 6300)
      SplitTime.create!(effort_id: @effort7.id, split_id: @split3.id, time_from_start: 6600)
      SplitTime.create!(effort_id: @effort7.id, split_id: @split4.id, time_from_start: 13000)
      SplitTime.create!(effort_id: @effort7.id, split_id: @split5.id, time_from_start: 13500)

      SplitTime.create!(effort_id: @effort8.id, split_id: @split1.id, time_from_start: 0)
      SplitTime.create!(effort_id: @effort8.id, split_id: @split2.id, time_from_start: 5500)
      SplitTime.create!(effort_id: @effort8.id, split_id: @split3.id, time_from_start: 5500)
      SplitTime.create!(effort_id: @effort8.id, split_id: @split6.id, time_from_start: 18700)

      SplitTime.create!(effort_id: @effort9.id, split_id: @split1.id, time_from_start: 0)
      SplitTime.create!(effort_id: @effort9.id, split_id: @split2.id, time_from_start: 11000)
      SplitTime.create!(effort_id: @effort9.id, split_id: @split3.id, time_from_start: 12000)
      SplitTime.create!(effort_id: @effort9.id, split_id: @split4.id, time_from_start: 20000)
      SplitTime.create!(effort_id: @effort9.id, split_id: @split6.id, time_from_start: 30000)
      SplitTime.create!(effort_id: @effort9.id, split_id: @split5.id, time_from_start: 22000)

      SplitTime.create!(effort_id: @effort10.id, split_id: @split1.id, time_from_start: 0)
      SplitTime.create!(effort_id: @effort10.id, split_id: @split2.id, time_from_start: 40240)
      SplitTime.create!(effort_id: @effort10.id, split_id: @split3.id, time_from_start: 4300)
      SplitTime.create!(effort_id: @effort10.id, split_id: @split4.id, time_from_start: 11000)
      SplitTime.create!(effort_id: @effort10.id, split_id: @split5.id, time_from_start: 11100)
      SplitTime.create!(effort_id: @effort10.id, split_id: @split6.id, time_from_start: 17600)

      SplitTime.create!(effort_id: @effort11.id, split_id: @split1.id, time_from_start: 0)
      SplitTime.create!(effort_id: @effort11.id, split_id: @split2.id, time_from_start: 6800)
      SplitTime.create!(effort_id: @effort11.id, split_id: @split3.id, time_from_start: 6800)
      SplitTime.create!(effort_id: @effort11.id, split_id: @split4.id, time_from_start: 24000)
      SplitTime.create!(effort_id: @effort11.id, split_id: @split5.id, time_from_start: 24200)
      SplitTime.create!(effort_id: @effort11.id, split_id: @split6.id, time_from_start: 33000)

      SplitTime.create!(effort_id: @effort12.id, split_id: @split1.id, time_from_start: 0)
      SplitTime.create!(effort_id: @effort12.id, split_id: @split2.id, time_from_start: 5300)
      SplitTime.create!(effort_id: @effort12.id, split_id: @split3.id, time_from_start: 5400)
      SplitTime.create!(effort_id: @effort12.id, split_id: @split4.id, time_from_start: 12500)
      SplitTime.create!(effort_id: @effort12.id, split_id: @split5.id, time_from_start: 12550)
      SplitTime.create!(effort_id: @effort12.id, split_id: @split6.id, time_from_start: 23232)

      SplitTime.create!(effort_id: @effort13.id, split_id: @split1.id, time_from_start: 0)
      SplitTime.create!(effort_id: @effort13.id, split_id: @split2.id, time_from_start: 4900)
      SplitTime.create!(effort_id: @effort13.id, split_id: @split3.id, time_from_start: 4940)
      SplitTime.create!(effort_id: @effort13.id, split_id: @split4.id, time_from_start: 13400)
      SplitTime.create!(effort_id: @effort13.id, split_id: @split5.id, time_from_start: 14300)
      SplitTime.create!(effort_id: @effort13.id, split_id: @split6.id, time_from_start: 19800)

      Effort.all.set_data_status

    end

    it 'should set the data status of the efforts to the lowest status of the split times' do
      expect(Effort.where(bib_number: 1).first.data_status).to eq('bad')
      expect(Effort.where(bib_number: 2).first.data_status).to eq('bad')
      expect(Effort.where(bib_number: 3).first.data_status).to eq('good')
      expect(Effort.where(bib_number: 8).first.data_status).to eq('good')
      expect(Effort.where(bib_number: 11).first.data_status).to eq('questionable')
    end

    it 'should set the data status of negative segment times to bad' do
      expect(@effort1.split_times.where(split_id: 5).first.bad?).to eq(true)
      expect(@effort4.split_times.where(split_id: 3).first.bad?).to eq(true)
    end

    it 'should look past bad data points to the previous valid data point to calculate data status' do
      expect(@effort2.split_times.where(split_id: 6).first.questionable?).to eq(true)
      expect(@effort10.split_times.where(split_id: 3).first.good?).to eq(true)

    end

    it 'should set the data status of split_times properly' do
      expect(@effort1.split_times.good.count).to eq(5)
      expect(@effort1.split_times.bad.count).to eq(1)
      expect(@effort2.split_times.good.count).to eq(2)
      expect(@effort2.split_times.questionable.count).to eq(1)
      expect(@effort2.split_times.bad.count).to eq(3)
      expect(@effort4.split_times.good.count).to eq(4)
      expect(@effort4.split_times.bad.count).to eq(2)
      expect(@effort11.split_times.good.count).to eq(4)
      expect(@effort11.split_times.questionable.count).to eq(2)
      expect(@effort11.split_times.bad.count).to eq(0)
    end

    it 'should set the data status of non-zero start splits to bad' do
      expect(@effort4.split_times.where(split_id: 1).first.data_status).to eq('bad')
    end

    it 'should set the data status of impossibly fast segments to bad' do
      expect(@effort2.split_times.where(split_id: 2).first.bad?).to eq(true)
      expect(@effort2.split_times.where(split_id: 3).first.bad?).to eq(true)
    end

    it 'should set the data status of impossibly slow segments to bad' do
      expect(@effort2.split_times.where(split_id: 5).first.bad?).to eq(true)
      expect(@effort10.split_times.where(split_id: 2).first.bad?).to eq(true)
    end

    it 'should set the data status of splits correctly even if missing prior splits' do
      expect(@effort6.split_times.where(split_id: 4).first.good?).to eq(true)
      expect(@effort8.split_times.where(split_id: 6).first.good?).to eq(true)
    end
  end

end