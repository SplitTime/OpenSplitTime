require 'rails_helper'

RSpec.describe Segment, type: :model do
  let(:start) { FactoryGirl.build_stubbed(:start_split, course_id: 10) }
  let(:aid_1) { FactoryGirl.build_stubbed(:split, base_name: 'Aid 1', course_id: 10, distance_from_start: 10000, vert_gain_from_start: 1000, vert_loss_from_start: 500) }
  let(:aid_2) { FactoryGirl.build_stubbed(:split, base_name: 'Aid 2', course_id: 10, distance_from_start: 25000, vert_gain_from_start: 2500, vert_loss_from_start: 1250) }
  let(:aid_3) { FactoryGirl.build_stubbed(:split, base_name: 'Aid 3', course_id: 10, distance_from_start: 45000, vert_gain_from_start: 4500, vert_loss_from_start: 2250) }
  let(:finish) { FactoryGirl.build_stubbed(:finish_split, course_id: 10, distance_from_start: 70000, vert_gain_from_start: 7000, vert_loss_from_start: 3500) }
  let(:start_in) { start.sub_split_in }
  let(:aid_1_in) { aid_1.sub_split_in }
  let(:aid_1_out) { aid_1.sub_split_out }
  let(:aid_2_in) { aid_2.sub_split_in }
  let(:aid_2_out) { aid_2.sub_split_out }
  let(:aid_3_in) { aid_3.sub_split_in }
  let(:aid_3_out) { aid_3.sub_split_out }
  let(:finish_in) { finish.sub_split_in }
  let(:start_to_aid_1) { Segment.new(begin_sub_split: start_in, end_sub_split: aid_1_in, begin_split: start, end_split: aid_1) }
  let(:start_to_aid_2) { Segment.new(begin_sub_split: start_in, end_sub_split: aid_2_in, begin_split: start, end_split: aid_2) }
  let(:start_to_aid_3) { Segment.new(begin_sub_split: start_in, end_sub_split: aid_3_in, begin_split: start, end_split: aid_3) }
  let(:start_to_finish) { Segment.new(begin_sub_split: start_in, end_sub_split: finish_in, begin_split: start, end_split: finish) }
  let(:aid_1_to_aid_2) { Segment.new(begin_sub_split: aid_1_out, end_sub_split: aid_2_in, begin_split: aid_1, end_split: aid_2) }
  let(:aid_2_to_aid_3) { Segment.new(begin_sub_split: aid_2_out, end_sub_split: aid_3_in, begin_split: aid_2, end_split: aid_3) }
  let(:aid_3_to_finish) { Segment.new(begin_sub_split: aid_3_out, end_sub_split: finish_in, begin_split: aid_3, end_split: finish) }
  let(:aid_1_to_finish) { Segment.new(begin_sub_split: aid_1_out, end_sub_split: finish_in, begin_split: aid_1, end_split: finish) }
  let(:aid_2_to_finish) { Segment.new(begin_sub_split: aid_2_out, end_sub_split: finish_in, begin_split: aid_2, end_split: finish) }
  let(:in_aid_1) { Segment.new(begin_sub_split: aid_1_in, end_sub_split: aid_1_out, begin_split: aid_1, end_split: aid_1) }
  let(:in_aid_2) { Segment.new(begin_sub_split: aid_2_in, end_sub_split: aid_2_out, begin_split: aid_2, end_split: aid_2) }
  let(:in_aid_3) { Segment.new(begin_sub_split: aid_3_in, end_sub_split: aid_3_out, begin_split: aid_3, end_split: aid_3) }
  let(:aid_1_to_aid_2_inclusive) { Segment.new(begin_sub_split: aid_1_in, end_sub_split: aid_2_out, begin_split: aid_1, end_split: aid_2) }
  let(:start_to_start) { Segment.new(begin_sub_split: start_in, end_sub_split: start_in, begin_split: start, end_split: start) }
  let(:aid_1_in_to_aid_1_in) { Segment.new(begin_sub_split: aid_1_in, end_sub_split: aid_1_in, begin_split: aid_1, end_split: aid_1) }
  let(:start_to_aid_1_duplicate) { Segment.new(begin_sub_split: start_in, end_sub_split: aid_1_in, begin_split: start, end_split: aid_1) }

  describe 'initialization' do
    it 'initializes when given a begin_sub_split and end_sub_split in an args hash' do
      begin_sub_split = aid_1.sub_split_in
      end_sub_split = aid_1.sub_split_out
      expect { Segment.new(begin_sub_split: begin_sub_split, end_sub_split: end_sub_split) }.not_to raise_error
    end

    it 'raises an error if missing begin_sub_split' do
      end_sub_split = aid_1.sub_split_out
      expect { Segment.new(end_sub_split: end_sub_split) }.to raise_error(/must include begin_sub_split/)
    end

    it 'raises an error if missing end_sub_split' do
      begin_sub_split = aid_1.sub_split_in
      expect { Segment.new(begin_sub_split: begin_sub_split) }.to raise_error(/must include end_sub_split/)
    end

    it 'raises an error when splits are out of order' do
      begin_sub_split = aid_2.sub_split_in
      end_sub_split = aid_1.sub_split_out
      begin_split = aid_2
      end_split = aid_1
      expect { Segment.new(begin_sub_split: begin_sub_split, end_sub_split: end_sub_split,
                           begin_split: begin_split, end_split: end_split) }
          .to raise_error(/Segment splits are out of order/)
    end

    it 'raises an error when sub_splits are out of order' do
      begin_sub_split = aid_1.sub_split_out
      end_sub_split = aid_1.sub_split_in
      expect { Segment.new(begin_sub_split: begin_sub_split, end_sub_split: end_sub_split) }
          .to raise_error(/Segment sub_splits are out of order/)
    end

    it 'does not raise an error when splits are out of order if order_control: false is given' do
      begin_sub_split = aid_2.sub_split_in
      end_sub_split = aid_1.sub_split_out
      begin_split = aid_2
      end_split = aid_1
      expect { Segment.new(begin_sub_split: begin_sub_split, end_sub_split: end_sub_split,
                           begin_split: begin_split, end_split: end_split, order_control: false) }
          .not_to raise_error
    end
  end

  describe '#==' do
    # Allows a segment to be used as a hash key and matched with another hash key
    it 'should equate itself with other segments using the same splits' do
      segment1 = start_to_aid_1
      segment2 = start_to_aid_1_duplicate
      expect(segment1 == segment2).to eq(true)
    end

    it 'should not equate itself with other segments using different splits' do
      segment1 = start_to_aid_1
      segment2 = start_to_aid_2
      expect(segment1 == segment2).to eq(false)
    end
  end

  describe '#name' do
    it 'should return a "Time in" name if it is within a waypoint group' do
      expect(in_aid_1.name).to eq('Time in Aid 1')
    end

    it 'should return a compound name if it is between waypoint groups' do
      expect(start_to_aid_1.name).to eq('Start Split to Aid 1')
      expect(aid_2_to_finish.name).to eq('Aid 2 to Finish Split')
    end

    it 'should return a single name if begin sub_split and end sub_split are the same' do
      expect(start_to_start.name).to eq('Start Split')
      expect(aid_1_in_to_aid_1_in.name).to eq('Aid 1 In')
    end
  end

  describe '#typical_time_by_terrain' do
    it 'should return a typical time based on the distance and vertical gain multiplied by constant factors' do
      expect(start_to_aid_1.typical_time_by_terrain).to eq(10000 * Segment::DISTANCE_FACTOR + 1000 * Segment::VERT_GAIN_FACTOR)
    end

    it 'should return zero for a segment in aid' do
      expect(in_aid_1.typical_time_by_terrain).to eq(0)
    end

    it 'should return zero for a segment having the same begin and end sub_splits' do
      expect(aid_1_in_to_aid_1_in.typical_time_by_terrain).to eq(0)
    end
  end

  describe '#distance' do
    it 'should return zero distance for in_aid segments' do
      expect(in_aid_1.distance).to eq(0)
      expect(in_aid_2.distance).to eq(0)
      expect(in_aid_3.distance).to eq(0)
    end

    it 'should calculate distance properly for single segments' do
      expect(start_to_aid_1.distance).to eq(10000)
      expect(aid_1_to_aid_2.distance).to eq(15000)
      expect(aid_2_to_aid_3.distance).to eq(20000)
      expect(aid_3_to_finish.distance).to eq(25000)
    end

    it 'should calculate distance properly for extended segments' do
      expect(start_to_aid_2.distance).to eq(25000)
      expect(start_to_aid_3.distance).to eq(45000)
      expect(start_to_finish.distance).to eq(70000)
      expect(aid_1_to_finish.distance).to eq(60000)
      expect(aid_2_to_finish.distance).to eq(45000)
    end

    it 'should return zero distance for segments with same start and end sub_split' do
      expect(aid_1_in_to_aid_1_in.distance).to eq(0)
    end

    it 'should calculate distance properly for unusual segments' do
      expect(aid_1_to_aid_2_inclusive.distance).to eq(15000)
    end
  end

  describe '#vert_gain' do
    it 'should return zero vert_gain for in_aid segments' do
      expect(in_aid_1.vert_gain).to eq(0)
      expect(in_aid_2.vert_gain).to eq(0)
      expect(in_aid_3.vert_gain).to eq(0)
    end

    it 'should calculate vert_gain properly for single segments' do
      expect(start_to_aid_1.vert_gain).to eq(1000)
      expect(aid_1_to_aid_2.vert_gain).to eq(1500)
      expect(aid_2_to_aid_3.vert_gain).to eq(2000)
      expect(aid_3_to_finish.vert_gain).to eq(2500)
    end

    it 'should calculate vert_gain properly for extended segments' do
      expect(start_to_aid_2.vert_gain).to eq(2500)
      expect(start_to_aid_3.vert_gain).to eq(4500)
      expect(start_to_finish.vert_gain).to eq(7000)
      expect(aid_1_to_finish.vert_gain).to eq(6000)
      expect(aid_2_to_finish.vert_gain).to eq(4500)
    end

    it 'should return zero vert_gain for segments with same start and end sub_split' do
      expect(aid_1_in_to_aid_1_in.vert_gain).to eq(0)
    end

    it 'should calculate vert_gain properly for unusual segments' do
      expect(aid_1_to_aid_2_inclusive.vert_gain).to eq(1500)
    end
  end

  describe '#vert_loss' do
    it 'should return zero vert_loss for in_aid segments' do
      expect(in_aid_1.vert_loss).to eq(0)
      expect(in_aid_2.vert_loss).to eq(0)
      expect(in_aid_3.vert_loss).to eq(0)
    end

    it 'should calculate vert_loss properly for single segments' do
      expect(start_to_aid_1.vert_loss).to eq(500)
      expect(aid_1_to_aid_2.vert_loss).to eq(750)
      expect(aid_2_to_aid_3.vert_loss).to eq(1000)
      expect(aid_3_to_finish.vert_loss).to eq(1250)
    end

    it 'should calculate vert_loss properly for extended segments' do
      expect(start_to_aid_2.vert_loss).to eq(1250)
      expect(start_to_aid_3.vert_loss).to eq(2250)
      expect(start_to_finish.vert_loss).to eq(3500)
      expect(aid_1_to_finish.vert_loss).to eq(3000)
      expect(aid_2_to_finish.vert_loss).to eq(2250)
    end

    it 'should return zero vert_loss for segments with same start and end sub_split' do
      expect(aid_1_in_to_aid_1_in.vert_loss).to eq(0)
    end

    it 'should calculate vert_loss properly for unusual segments' do
      expect(aid_1_to_aid_2_inclusive.vert_loss).to eq(750)
    end
  end

  describe '#full_course' do
    it 'should accurately report whether it represents an entire course' do
      expect(start_to_finish.full_course?).to eq(true)
      expect(start_to_aid_1.full_course?).to eq(false)
      expect(in_aid_1.full_course?).to eq(false)
    end
  end

  describe '#special_limits_type' do
    it 'should return :start for a segment consisting of start split only' do
      expect(start_to_start.special_limits_type).to eq(:start)
    end

    it 'should return :in_aid for an in-aid segment' do
      expect(in_aid_1.special_limits_type).to eq(:in_aid)
    end

    it 'should return nil for segments between splits' do
      expect(start_to_aid_1.special_limits_type).to be_nil
      expect(start_to_finish.special_limits_type).to be_nil
      expect(aid_1_to_aid_2_inclusive.special_limits_type).to be_nil
    end
  end

  xdescribe 'times' do
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

      @segment1 = Segment.new(begin_sub_split: @split1.sub_split_in, end_sub_split: @split2.sub_split_in)
      @segment2 = Segment.new(begin_sub_split: @split2.sub_split_in, end_sub_split: @split2.sub_split_out)
      @segment3 = Segment.new(begin_sub_split: @split1.sub_split_in, end_sub_split: @split4.sub_split_in)
      @segment4 = Segment.new(begin_sub_split: @split2.sub_split_out, end_sub_split: @split4.sub_split_in)

      SplitTime.create!(effort: @effort1, split: @split1, bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort1, split: @split2, bitkey: SubSplit::IN_BITKEY, time_from_start: 4000)
      SplitTime.create!(effort: @effort1, split: @split2, bitkey: SubSplit::OUT_BITKEY, time_from_start: 4100)
      SplitTime.create!(effort: @effort1, split: @split4, bitkey: SubSplit::IN_BITKEY, time_from_start: 8000)
      SplitTime.create!(effort: @effort2, split: @split1, bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort2, split: @split2, bitkey: SubSplit::IN_BITKEY, time_from_start: 5000)
      SplitTime.create!(effort: @effort2, split: @split2, bitkey: SubSplit::OUT_BITKEY, time_from_start: 5000)
      SplitTime.create!(effort: @effort2, split: @split4, bitkey: SubSplit::IN_BITKEY, time_from_start: 9000)
      SplitTime.create!(effort: @effort3, split: @split1, bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
      SplitTime.create!(effort: @effort3, split: @split2, bitkey: SubSplit::IN_BITKEY, time_from_start: 6000)
      SplitTime.create!(effort: @effort3, split: @split2, bitkey: SubSplit::OUT_BITKEY, time_from_start: 9200)
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
end