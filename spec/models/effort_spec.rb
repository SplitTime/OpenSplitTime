require 'rails_helper'
require 'pry-byebug'

# t.integer  "event_id",                  null: false
# t.integer  "participant_id"
# t.string   "wave"
# t.integer  "bib_number"
# t.string   "city",           limit: 64
# t.string   "state_code",     limit: 64
# t.integer  "age"
# t.boolean  "dropped_split_id"
# t.string   "first_name"
# t.string   "last_name"
# t.integer  "gender"
# t.string   "country_code",   limit: 2
# t.date     "birthdate"
# t.integer  "data_status"
# t.integer  "start_offset"

RSpec.describe Effort, type: :model do
  it { is_expected.to strip_attribute(:first_name).collapse_spaces }
  it { is_expected.to strip_attribute(:last_name).collapse_spaces }
  it { is_expected.to strip_attribute(:state_code).collapse_spaces }
  it { is_expected.to strip_attribute(:country_code).collapse_spaces }

  describe "validations" do

    before :each do
      @course = Course.create!(name: 'Test Course')
      @event = Event.create!(course: @course, race: nil, name: 'Test Event', start_time: "2012-08-08 05:00:00")
      @location1 = Location.create!(name: 'Mountain Town', elevation: 2400, latitude: 40.1, longitude: -105)
      @location2 = Location.create!(name: 'Mountain Hideout', elevation: 2900, latitude: 40.3, longitude: -105.05)
      @participant = Participant.create!(first_name: 'Joe', last_name: 'Hardman',
                                         gender: 'male', birthdate: "1989-12-15",
                                         city: 'Boulder', state_code: 'CO', country_code: 'US')
    end

    it "should be valid when created with an event_id, first_name, last_name, and gender" do
      @event = Event.create!(course: @course, name: 'Hardrock 2015', start_time: "2015-07-01 06:00:00")
      Effort.create!(event: @event, first_name: 'David', last_name: 'Goliath', gender: 'male')

      expect(Effort.all.count).to(equal(1))
      expect(Effort.first.event).to eq(@event)
      expect(Effort.first.last_name).to eq('Goliath')
    end

    it "should be invalid without an event_id" do
      effort = Effort.new(event: nil, first_name: 'David', last_name: 'Goliath', gender: 'male')
      expect(effort).not_to be_valid
      expect(effort.errors[:event_id]).to include("can't be blank")
    end

    it "should be invalid without a first_name" do
      effort = Effort.new(event: @event, first_name: nil, last_name: 'Appleseed', gender: 'male')
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
      Effort.create!(event: @event, first_name: 'David', last_name: 'Goliath', gender: 'male',
                     participant: @participant)
      effort = Effort.new(event: @event, first_name: 'David', last_name: 'Goliath', gender: 'male',
                          participant: @participant)
      expect(effort).not_to be_valid
      expect(effort.errors[:participant_id]).to include("has already been taken")
    end

    it "should not permit duplicate bib_numbers within a given event" do
      Effort.create!(event: @event, first_name: 'David', last_name: 'Goliath', gender: 'male', bib_number: 20)
      effort = Effort.new(event: @event, participant_id: 2, bib_number: 20)
      expect(effort).not_to be_valid
      expect(effort.errors[:bib_number]).to include("has already been taken")
    end
  end

  describe 'within_time_range' do
    before do

      @course = Course.create!(name: 'Test Course 100')
      @event = Event.create!(name: 'Test Event 2015', course: @course, start_time: "2015-07-01 06:00:00")
      
      @location1 = Location.create!(name: 'Mountain Town', elevation: 2400, latitude: 40.1, longitude: -105)
      @location2 = Location.create!(name: 'Mountain Hideout', elevation: 2900, latitude: 40.3, longitude: -105.05)

      @effort1 = Effort.create!(event: @event, bib_number: 99, city: 'Vancouver', state_code: 'BC', country_code: 'CA', age: 50, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      @effort2 = Effort.create!(event: @event, bib_number: 12, city: 'Boulder', state_code: 'CO', country_code: 'US', age: 23, first_name: 'Joe', last_name: 'Hardman', gender: 'male')
      @effort3 = Effort.create!(event: @event, bib_number: 150, city: 'Nantucket', state_code: 'MA', country_code: 'US', age: 26, first_name: 'Jane', last_name: 'Rockstar', gender: 'female')

      @split1 = Split.create!(course: @course, location: @location1, base_name: 'Test Starting Line', distance_from_start: 0, vert_gain_from_start: 0, vert_loss_from_start: 0, kind: 0)
      @split3 = Split.create!(course: @course, location: @location2, base_name: 'Test Aid Station', distance_from_start: 6000, sub_split_bitmap: 65, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split4 = Split.create!(course: @course, location: @location1, base_name: 'Test Finish Line', distance_from_start: 10000, vert_gain_from_start: 700, vert_loss_from_start: 700, kind: 1)

      @event.splits << @course.splits

      SplitTime.create!(effort: @effort1, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort1, split: @split3, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 4000)
      SplitTime.create!(effort: @effort1, split: @split3, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 4100)
      SplitTime.create!(effort: @effort1, split: @split4, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 8000)
      SplitTime.create!(effort: @effort2, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort2, split: @split3, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 5000)
      SplitTime.create!(effort: @effort2, split: @split3, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 5100)
      SplitTime.create!(effort: @effort2, split: @split4, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 9000)
      SplitTime.create!(effort: @effort3, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort3, split: @split3, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 3000)
      SplitTime.create!(effort: @effort3, split: @split3, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 3100)
      SplitTime.create!(effort: @effort3, split: @split4, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 7500)

    end

    it 'should return only those efforts for which the finish time is between the parameters provided' do
      efforts = Effort.all
      expect(efforts.within_time_range(7800, 8200).count).to eq(1)
      expect(efforts.within_time_range(5000, 10000).count).to eq(3)
      expect(efforts.within_time_range(10000, 20000).count).to eq(0)
    end

  end

  describe 'expected_time_from_start' do
    before do

      @course = Course.create!(name: 'Test Course 100')
      @event = Event.create!(name: 'Test Event 2015', course: @course, start_time: "2015-07-01 06:00:00")

      @effort1 = Effort.create!(event: @event, bib_number: 1, city: 'Vancouver', state_code: 'BC', country_code: 'CA', age: 50, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      @effort2 = Effort.create!(event: @event, bib_number: 2, city: 'Boulder', state_code: 'CO', country_code: 'US', age: 23, first_name: 'Joe', last_name: 'Hardman', gender: 'male')

      @split1 = Split.create!(course: @course, base_name: 'Starting Line', distance_from_start: 0, vert_gain_from_start: 0, vert_loss_from_start: 0, kind: 0)
      @split2 = Split.create!(course: @course, base_name: 'Aid Station 1', distance_from_start: 6000, sub_split_bitmap: 65, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split4 = Split.create!(course: @course, base_name: 'Aid Station 2', distance_from_start: 15000, sub_split_bitmap: 65, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split6 = Split.create!(course: @course, base_name: 'Finish Line', distance_from_start: 25000, vert_gain_from_start: 700, vert_loss_from_start: 700, kind: 1)

      @event.splits << @course.splits

      SplitTime.create!(effort: @effort1, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort1, split: @split2, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 4000)
      SplitTime.create!(effort: @effort1, split: @split2, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 4100)
      SplitTime.create!(effort: @effort1, split: @split4, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 15200)
      SplitTime.create!(effort: @effort1, split: @split4, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 15100)

      SplitTime.create!(effort: @effort2, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort2, split: @split2, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 6000)
      SplitTime.create!(effort: @effort2, split: @split2, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 6200)

    end

    it 'should return zero if the split parameter is a start split' do
      expect(@effort1.expected_time_from_start(@split1.sub_split_bitkey_hashes.first)).to eq(0)
    end

    context 'insufficient historical data' do

      it 'should determine expected time based on most recent time from start and segment mileage/vertical' do
        expect(@effort1.expected_time_from_start(@split2.bitkey_hash_in)).to eq((6000 * DISTANCE_FACTOR) + (500 * VERT_GAIN_FACTOR))
        expect(@effort1.expected_time_from_start(@split4.bitkey_hash_in)).to eq(4100 + (((15000 - 6000) * DISTANCE_FACTOR) + ((500 - 500) * VERT_GAIN_FACTOR)) * (4100 / ((6000 * DISTANCE_FACTOR) + (500 * VERT_GAIN_FACTOR))))
      end

    end

    context 'sufficient historical data' do

      before do

        @effort3 = Effort.create!(event: @event, bib_number: 3, city: 'Denver', state_code: 'CO', country_code: 'US', age: 24, first_name: 'Mark', last_name: 'Runner', gender: 'male')
        @effort4 = Effort.create!(event: @event, bib_number: 4, city: 'Louisville', state_code: 'CO', country_code: 'US', age: 25, first_name: 'Pete', last_name: 'Trotter', gender: 'male')
        @effort5 = Effort.create!(event: @event, bib_number: 5, city: 'Fort Collins', state_code: 'CO', country_code: 'US', age: 26, first_name: 'James', last_name: 'Walker', gender: 'male')
        @effort6 = Effort.create!(event: @event, bib_number: 6, city: 'Colorado Springs', state_code: 'CO', country_code: 'US', age: 27, first_name: 'Johnny', last_name: 'Hiker', gender: 'male')
        @effort7 = Effort.create!(event: @event, bib_number: 7, city: 'Idaho Springs', state_code: 'CO', country_code: 'US', age: 28, first_name: 'Melissa', last_name: 'Getter', gender: 'female')
        @effort8 = Effort.create!(event: @event, bib_number: 8, city: 'Grand Junction', state_code: 'CO', country_code: 'US', age: 29, first_name: 'George', last_name: 'Ringer', gender: 'male')
        @effort9 = Effort.create!(event: @event, bib_number: 9, city: 'Aspen', state_code: 'CO', country_code: 'US', age: 30, first_name: 'Abe', last_name: 'Goer', gender: 'male')
        @effort10 = Effort.create!(event: @event, bib_number: 10, city: 'Vail', state_code: 'CO', country_code: 'US', age: 31, first_name: 'Tanya', last_name: 'Doer', gender: 'female')
        @effort11 = Effort.create!(event: @event, bib_number: 11, city: 'Frisco', state_code: 'CO', country_code: 'US', age: 32, first_name: 'Sally', last_name: 'Tracker', gender: 'female')
        @effort12 = Effort.create!(event: @event, bib_number: 12, city: 'Glenwood Springs', state_code: 'CO', country_code: 'US', age: 32, first_name: 'Linus', last_name: 'Peanut', gender: 'male')
        @effort13 = Effort.create!(event: @event, bib_number: 13, city: 'Limon', state_code: 'CO', country_code: 'US', age: 32, first_name: 'Lucy', last_name: 'Peanut', gender: 'female')

        SplitTime.create!(effort: @effort3, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
        SplitTime.create!(effort: @effort3, split: @split2, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 5000)
        SplitTime.create!(effort: @effort3, split: @split2, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 5000)
        SplitTime.create!(effort: @effort3, split: @split4, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 12200)
        SplitTime.create!(effort: @effort3, split: @split4, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 12300)
        SplitTime.create!(effort: @effort3, split: @split6, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 18000)

        SplitTime.create!(effort: @effort4, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 1000)
        SplitTime.create!(effort: @effort4, split: @split2, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 4500)
        SplitTime.create!(effort: @effort4, split: @split2, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 4400)
        SplitTime.create!(effort: @effort4, split: @split4, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 11000)
        SplitTime.create!(effort: @effort4, split: @split4, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 11000)
        SplitTime.create!(effort: @effort4, split: @split6, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 17500)

        SplitTime.create!(effort: @effort5, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
        SplitTime.create!(effort: @effort5, split: @split2, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 4600)
        SplitTime.create!(effort: @effort5, split: @split2, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 4800)
        SplitTime.create!(effort: @effort5, split: @split4, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 9800)
        SplitTime.create!(effort: @effort5, split: @split4, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 10000)
        SplitTime.create!(effort: @effort5, split: @split6, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 14550)

        SplitTime.create!(effort: @effort6, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
        SplitTime.create!(effort: @effort6, split: @split4, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 9600)
        SplitTime.create!(effort: @effort6, split: @split4, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 9660)
        SplitTime.create!(effort: @effort6, split: @split6, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 14650)

        SplitTime.create!(effort: @effort7, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
        SplitTime.create!(effort: @effort7, split: @split2, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 6300)
        SplitTime.create!(effort: @effort7, split: @split2, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 6600)
        SplitTime.create!(effort: @effort7, split: @split4, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 13000)
        SplitTime.create!(effort: @effort7, split: @split4, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 13500)

        SplitTime.create!(effort: @effort8, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
        SplitTime.create!(effort: @effort8, split: @split2, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 5500)
        SplitTime.create!(effort: @effort8, split: @split2, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 5500)
        SplitTime.create!(effort: @effort8, split: @split6, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 18700)

        SplitTime.create!(effort: @effort9, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
        SplitTime.create!(effort: @effort9, split: @split2, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 11000)
        SplitTime.create!(effort: @effort9, split: @split2, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 12000)

        SplitTime.create!(effort: @effort10, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
        SplitTime.create!(effort: @effort10, split: @split2, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 4200)
        SplitTime.create!(effort: @effort10, split: @split2, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 4300)
        SplitTime.create!(effort: @effort10, split: @split4, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 11000)
        SplitTime.create!(effort: @effort10, split: @split4, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 11100)
        SplitTime.create!(effort: @effort10, split: @split6, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 17600)

        SplitTime.create!(effort: @effort11, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
        SplitTime.create!(effort: @effort11, split: @split2, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 6800)
        SplitTime.create!(effort: @effort11, split: @split2, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 6800)

        SplitTime.create!(effort: @effort12, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
        SplitTime.create!(effort: @effort12, split: @split2, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 5300)
        SplitTime.create!(effort: @effort12, split: @split2, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 5400)
        SplitTime.create!(effort: @effort12, split: @split4, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 12500)
        SplitTime.create!(effort: @effort12, split: @split4, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 12550)

        SplitTime.create!(effort: @effort13, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
        SplitTime.create!(effort: @effort13, split: @split2, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 4900)
        SplitTime.create!(effort: @effort13, split: @split2, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 4940)
        SplitTime.create!(effort: @effort13, split: @split4, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 13400)
        SplitTime.create!(effort: @effort13, split: @split4, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 14300)
        SplitTime.create!(effort: @effort13, split: @split6, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 19800)

        @segment1 = Segment.new(@split1.bitkey_hash_in, @split2.bitkey_hash_in)
        @segment2 = Segment.new(@split1.bitkey_hash_in, @split4.bitkey_hash_in)
        @segment3 = Segment.new(@split1.bitkey_hash_in, @split6.bitkey_hash_in)
        @segment4 = Segment.new(@split2.bitkey_hash_out, @split4.bitkey_hash_in)
        @segment5 = Segment.new(@split4.bitkey_hash_out, @split6.bitkey_hash_in)
        @segment6 = Segment.new(@split1.bitkey_hash_in, @split2.bitkey_hash_out)
        @segment7 = Segment.new(@split1.bitkey_hash_in, @split4.bitkey_hash_out)

        @calcs1 = SegmentCalculations.new(@segment1)
        @calcs2 = SegmentCalculations.new(@segment2)
        @calcs3 = SegmentCalculations.new(@segment3)
        @calcs4 = SegmentCalculations.new(@segment4)
        @calcs5 = SegmentCalculations.new(@segment5)
        @calcs6 = SegmentCalculations.new(@segment6)
        @calcs7 = SegmentCalculations.new(@segment7)

      end

      it 'should determine expected time based on prior split_time and mean segment time (normalized to effort)' do
        expect(@effort1.expected_time_from_start(@split2.bitkey_hash_in)).to eq(@calcs1.mean)
        expect(@effort2.expected_time_from_start(@split4.bitkey_hash_in)).to eq(6200 + ((6200 / @calcs6.mean) * @calcs4.mean))
        expect(@effort12.expected_time_from_start(@split6.bitkey_hash_in)).to eq(12550 + ((12550 / @calcs7.mean) * @calcs5.mean))
      end

    end
  end
end