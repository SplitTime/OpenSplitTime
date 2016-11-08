require 'rails_helper'
require 'pry-byebug'

RSpec.describe Segment, type: :model do

  describe 'initialization' do
    before do

      @course = Course.create!(name: 'Test Course 100')
      @event = Event.create!(name: 'Test Event 2015', course: @course, start_time: "2015-07-01 06:00:00")

      @effort1 = Effort.create!(event: @event, bib_number: 1, city: 'Vancouver', state_code: 'BC', country_code: 'CA', age: 50, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      @effort2 = Effort.create!(event: @event, bib_number: 2, city: 'Boulder', state_code: 'CO', country_code: 'US', age: 23, first_name: 'Joe', last_name: 'Hardman', gender: 'male')
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

      @split1 = Split.create!(course: @course, base_name: 'Starting Line', distance_from_start: 0, sub_split_bitmap: 1, vert_gain_from_start: 0, vert_loss_from_start: 0, kind: 0)
      @split2 = Split.create!(course: @course, base_name: 'Aid Station 1', distance_from_start: 6000, sub_split_bitmap: 65, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split4 = Split.create!(course: @course, base_name: 'Aid Station 2', distance_from_start: 15000, sub_split_bitmap: 65, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split6 = Split.create!(course: @course, base_name: 'Finish Line', distance_from_start: 25000, sub_split_bitmap: 1, vert_gain_from_start: 700, vert_loss_from_start: 700, kind: 1)

      @event.splits << @course.splits

      SplitTime.create!(effort: @effort1, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort1, split: @split2, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 4000)
      SplitTime.create!(effort: @effort1, split: @split2, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 4100)
      SplitTime.create!(effort: @effort1, split: @split4, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 15200)
      SplitTime.create!(effort: @effort1, split: @split4, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 15100)
      SplitTime.create!(effort: @effort1, split: @split6, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 21000)

      SplitTime.create!(effort: @effort2, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort2, split: @split2, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 60)
      SplitTime.create!(effort: @effort2, split: @split2, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 120)
      SplitTime.create!(effort: @effort2, split: @split4, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 24000)
      SplitTime.create!(effort: @effort2, split: @split4, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 150000)
      SplitTime.create!(effort: @effort2, split: @split6, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 40000)

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
      SplitTime.create!(effort: @effort9, split: @split4, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 20000)
      SplitTime.create!(effort: @effort9, split: @split6, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 30000)
      SplitTime.create!(effort: @effort9, split: @split4, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 22000)

      SplitTime.create!(effort: @effort10, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort10, split: @split2, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 40240)
      SplitTime.create!(effort: @effort10, split: @split2, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 4300)
      SplitTime.create!(effort: @effort10, split: @split4, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 11000)
      SplitTime.create!(effort: @effort10, split: @split4, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 11100)
      SplitTime.create!(effort: @effort10, split: @split6, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 17600)

      SplitTime.create!(effort: @effort11, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort11, split: @split2, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 6800)
      SplitTime.create!(effort: @effort11, split: @split2, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 6800)
      SplitTime.create!(effort: @effort11, split: @split4, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 24000)
      SplitTime.create!(effort: @effort11, split: @split4, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 24200)
      SplitTime.create!(effort: @effort11, split: @split6, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 33000)

      SplitTime.create!(effort: @effort12, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort12, split: @split2, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 5300)
      SplitTime.create!(effort: @effort12, split: @split2, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 5400)
      SplitTime.create!(effort: @effort12, split: @split4, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 12500)
      SplitTime.create!(effort: @effort12, split: @split4, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 12550)
      SplitTime.create!(effort: @effort12, split: @split6, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 23232)

      SplitTime.create!(effort: @effort13, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort13, split: @split2, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 4900)
      SplitTime.create!(effort: @effort13, split: @split2, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 4940)
      SplitTime.create!(effort: @effort13, split: @split4, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 13400)
      SplitTime.create!(effort: @effort13, split: @split4, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 14300)
      SplitTime.create!(effort: @effort13, split: @split6, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 19800)

      @segment1 = Segment.new(@split1.bitkey_hash_in, @split6.bitkey_hash_in)
      @segment2 = Segment.new(@split2.bitkey_hash_in, @split2.bitkey_hash_out)
      @segment3 = Segment.new(@split2.bitkey_hash_out, @split4.bitkey_hash_in)
      @segment4 = Segment.new(@split4.bitkey_hash_out, @split6.bitkey_hash_in)

    end

    it 'should calculate distance properly based on provided splits' do
      expect(@segment1.distance).to eq(25000)
      expect(@segment2.distance).to eq(0)
      expect(@segment3.distance).to eq(9000)
      expect(@segment4.distance).to eq(10000)
    end

    it 'should equate itself with other segments using the same splits' do
      # This allows a segment to be used as a hash key and matched with another hash key
      segment5 = Segment.new(@split1.bitkey_hash_in, @split6.bitkey_hash_in)
      segment6 = Segment.new(@split2.bitkey_hash_out, @split4.bitkey_hash_in)
      expect(segment5 == @segment1).to eq(true)
      expect(segment6 == @segment3).to eq(true)
      expect(segment6 == @segment2).to eq(false)
    end

    it 'should accurately report whether it represents an entire course' do
      expect(@segment1.full_course?).to eq(true)
      expect(@segment2.full_course?).to eq(false)
      expect(@segment4.full_course?).to eq(false)

    end

  end

  describe 'times' do
    before do
      @course = Course.create!(name: 'Test Course 100')
      @event = Event.create!(name: 'Test Event 2015', course: @course, start_time: "2015-07-01 06:00:00")

      @effort1 = Effort.create!(event: @event, bib_number: 99, city: 'Vancouver', state_code: 'BC', country_code: 'CA', age: 50, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      @effort2 = Effort.create!(event: @event, bib_number: 12, city: 'Boulder', state_code: 'CO', country_code: 'US', age: 23, first_name: 'Joe', last_name: 'Hardman', gender: 'male')
      @effort3 = Effort.create!(event: @event, bib_number: 13, city: 'Boulder', state_code: 'CO', country_code: 'US', age: 23, first_name: 'Jon', last_name: 'Henkla', gender: 'male')

      @split1 = Split.create!(course: @course, base_name: 'Test Starting Line', distance_from_start: 0, sub_split_bitmap: 1, vert_gain_from_start: 0, vert_loss_from_start: 0, kind: 0)
      @split2 = Split.create!(course: @course, base_name: 'Test Aid Station', distance_from_start: 6000, sub_split_bitmap: 65, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split4 = Split.create!(course: @course, base_name: 'Test Finish Line', distance_from_start: 10000, sub_split_bitmap: 1, vert_gain_from_start: 700, vert_loss_from_start: 700, kind: 1)

      @event.splits << @course.splits

      @segment1 = Segment.new(@split1.bitkey_hash_in, @split2.bitkey_hash_in)
      @segment2 = Segment.new(@split2.bitkey_hash_in, @split2.bitkey_hash_out)
      @segment3 = Segment.new(@split1.bitkey_hash_in, @split4.bitkey_hash_in)
      @segment4 = Segment.new(@split2.bitkey_hash_out, @split4.bitkey_hash_in)

      SplitTime.create!(effort: @effort1, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort1, split: @split2, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 4000)
      SplitTime.create!(effort: @effort1, split: @split2, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 4100)
      SplitTime.create!(effort: @effort1, split: @split4, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 8000)
      SplitTime.create!(effort: @effort2, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort2, split: @split2, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 5000)
      SplitTime.create!(effort: @effort2, split: @split2, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 5000)
      SplitTime.create!(effort: @effort2, split: @split4, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 9000)
      SplitTime.create!(effort: @effort3, split: @split1, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort3, split: @split2, sub_split_bitkey: SubSplit::IN_BITKEY, time_from_start: 6000)
      SplitTime.create!(effort: @effort3, split: @split2, sub_split_bitkey: SubSplit::OUT_BITKEY, time_from_start: 9200)
    end

    it 'should return a hash containing effort => time for the segment' do
      expect(@segment1.times.count).to eq(3)
      expect(@segment2.times.count).to eq(3)
      expect(@segment3.times.count).to eq(2)
      expect(@segment1.times[@effort1.id]).to eq(4000)
      expect(@segment3.times[@effort2.id]).to eq(9000)
      expect(@segment4.times[@effort1.id]).to eq(3900)
      expect(@segment3.times[@effort3.id]).to be_nil
    end
  end

  describe 'name' do
    before do
      @course = Course.create!(name: 'Test Course 100')
      @event = Event.create!(name: 'Test Event 2015', course: @course, start_time: "2015-07-01 06:00:00")

      @effort1 = Effort.create!(event: @event, bib_number: 99, city: 'Vancouver', state_code: 'BC', country_code: 'CA', age: 50, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      @effort2 = Effort.create!(event: @event, bib_number: 12, city: 'Boulder', state_code: 'CO', country_code: 'US', age: 23, first_name: 'Joe', last_name: 'Hardman', gender: 'male')
      @effort3 = Effort.create!(event: @event, bib_number: 13, city: 'Boulder', state_code: 'CO', country_code: 'US', age: 23, first_name: 'Jon', last_name: 'Henkla', gender: 'male')

      @split1 = Split.create!(course: @course, base_name: 'Start', distance_from_start: 0, sub_split_bitmap: 1, vert_gain_from_start: 0, vert_loss_from_start: 0, kind: 0)
      @split2 = Split.create!(course: @course, base_name: 'Aid Station', distance_from_start: 6000, sub_split_bitmap: 65, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
      @split4 = Split.create!(course: @course, base_name: 'Finish', distance_from_start: 10000, sub_split_bitmap: 1, vert_gain_from_start: 700, vert_loss_from_start: 700, kind: 1)

      @event.splits << @course.splits

      @segment1 = Segment.new(@split1.bitkey_hash_in, @split2.bitkey_hash_in)
      @segment2 = Segment.new(@split2.bitkey_hash_in, @split2.bitkey_hash_out)
      @segment3 = Segment.new(@split1.bitkey_hash_in, @split4.bitkey_hash_in)
      @segment4 = Segment.new(@split2.bitkey_hash_out, @split4.bitkey_hash_in)


    end

    it 'should return a "Time in" name if it is within a waypoint group' do
      expect(@segment2.name).to eq('Time in Aid Station')
    end

    it 'should return a compound name if it is between waypoint groups' do
      expect(@segment1.name).to eq('Start to Aid Station')
      expect(@segment4.name).to eq('Aid Station to Finish')
    end
  end

end