require 'rails_helper'

RSpec.describe Segment, type: :model do
  let(:lap_1) { 1 }
  let(:lap_2) { 2 }
  let(:start_split) { FactoryGirl.build_stubbed(:start_split, course_id: 10) }
  let(:aid_1_split) { FactoryGirl.build_stubbed(:split, base_name: 'Aid 1', course_id: 10, distance_from_start: 10000, vert_gain_from_start: 1000, vert_loss_from_start: 500) }
  let(:aid_2_split) { FactoryGirl.build_stubbed(:split, base_name: 'Aid 2', course_id: 10, distance_from_start: 25000, vert_gain_from_start: 2500, vert_loss_from_start: 1250) }
  let(:aid_3_split) { FactoryGirl.build_stubbed(:split, base_name: 'Aid 3', course_id: 10, distance_from_start: 45000, vert_gain_from_start: 4500, vert_loss_from_start: 2250) }
  let(:finish_split) { FactoryGirl.build_stubbed(:finish_split, course_id: 10, distance_from_start: 70000, vert_gain_from_start: 7000, vert_loss_from_start: 3500) }
  let(:lap_1_start) { LapSplit.new(lap_1, start_split) }
  let(:lap_1_aid_1) { LapSplit.new(lap_1, aid_1_split) }
  let(:lap_1_aid_2) { LapSplit.new(lap_1, aid_2_split) }
  let(:lap_1_aid_3) { LapSplit.new(lap_1, aid_3_split) }
  let(:lap_1_finish) { LapSplit.new(lap_1, finish_split) }
  let(:lap_2_start) { LapSplit.new(lap_2, start_split) }
  let(:lap_2_aid_1) { LapSplit.new(lap_2, aid_1_split) }
  let(:lap_2_aid_2) { LapSplit.new(lap_2, aid_2_split) }
  let(:lap_2_aid_3) { LapSplit.new(lap_2, aid_3_split) }
  let(:lap_2_finish) { LapSplit.new(lap_2, finish_split) }
  let(:lap_1_start_to_lap_1_aid_1) { Segment.new(begin_point: lap_1_start.time_point_in, end_point: lap_1_aid_1.time_point_in, begin_split: start_split, end_split: aid_1_split) }
  let(:lap_1_start_to_lap_1_aid_2) { Segment.new(begin_point: lap_1_start.time_point_in, end_point: lap_1_aid_2.time_point_in, begin_split: start_split, end_split: aid_2_split) }
  let(:lap_1_start_to_lap_1_aid_3) { Segment.new(begin_point: lap_1_start.time_point_in, end_point: lap_1_aid_3.time_point_in, begin_split: start_split, end_split: aid_3_split) }
  let(:lap_1_start_to_lap_1_finish) { Segment.new(begin_point: lap_1_start.time_point_in, end_point: lap_1_finish.time_point_in, begin_split: start_split, end_split: finish_split) }
  let(:lap_1_aid_1_to_lap_1_aid_2) { Segment.new(begin_point: lap_1_aid_1.time_point_out, end_point: lap_1_aid_2.time_point_in, begin_split: aid_1_split, end_split: aid_2_split) }
  let(:lap_1_aid_2_to_lap_1_aid_3) { Segment.new(begin_point: lap_1_aid_2.time_point_out, end_point: lap_1_aid_3.time_point_in, begin_split: aid_2_split, end_split: aid_3_split) }
  let(:lap_1_aid_3_to_lap_1_finish) { Segment.new(begin_point: lap_1_aid_3.time_point_out, end_point: lap_1_finish.time_point_in, begin_split: aid_3_split, end_split: finish_split) }
  let(:lap_1_aid_1_to_lap_1_finish) { Segment.new(begin_point: lap_1_aid_1.time_point_out, end_point: lap_1_finish.time_point_in, begin_split: aid_1_split, end_split: finish_split) }
  let(:lap_1_aid_2_to_lap_1_finish) { Segment.new(begin_point: lap_1_aid_2.time_point_out, end_point: lap_1_finish.time_point_in, begin_split: aid_2_split, end_split: finish_split) }
  let(:lap_1_in_aid_1) { Segment.new(begin_point: lap_1_aid_1.time_point_in, end_point: lap_1_aid_1.time_point_out, begin_split: aid_1_split, end_split: aid_1_split) }
  let(:lap_1_in_aid_2) { Segment.new(begin_point: lap_1_aid_2.time_point_in, end_point: lap_1_aid_2.time_point_out, begin_split: aid_2_split, end_split: aid_2_split) }
  let(:lap_1_in_aid_3) { Segment.new(begin_point: lap_1_aid_3.time_point_in, end_point: lap_1_aid_3.time_point_out, begin_split: aid_3_split, end_split: aid_3_split) }
  let(:lap_1_aid_1_to_lap_1_aid_2_inclusive) { Segment.new(begin_point: lap_1_aid_1.time_point_in, end_point: lap_1_aid_2.time_point_out, begin_split: aid_1_split, end_split: aid_2_split) }
  let(:lap_1_start_to_lap_1_start) { Segment.new(begin_point: lap_1_start.time_point_in, end_point: lap_1_start.time_point_in, begin_split: start_split, end_split: start_split) }
  let(:aid_1_in_to_aid_1_in) { Segment.new(begin_point: lap_1_aid_1.time_point_in, end_point: lap_1_aid_1.time_point_in, begin_split: aid_1_split, end_split: aid_1_split) }
  let(:lap_1_start_to_lap_1_aid_1_duplicate) { Segment.new(begin_point: lap_1_start.time_point_in, end_point: lap_1_aid_1.time_point_in, begin_split: start_split, end_split: aid_1_split) }
  let(:lap_2_start_to_lap_2_start) { Segment.new(begin_point: lap_2_start.time_point_in, end_point: lap_2_start.time_point_in, begin_split: start_split, end_split: start_split) }

  describe 'initialization' do
    it 'initializes when given a begin_point and end_point in an args hash' do
      begin_point = lap_1_aid_1.time_point_in
      end_point = lap_1_aid_1.time_point_out
      expect { Segment.new(begin_point: begin_point, end_point: end_point) }.not_to raise_error
    end

    it 'raises an error if missing begin_point' do
      end_point = lap_1_aid_1.time_point_out
      expect { Segment.new(end_point: end_point) }.to raise_error(/must include one of begin_point/)
    end

    it 'raises an error if missing end_point' do
      begin_point = lap_1_aid_1.time_point_in
      expect { Segment.new(begin_point: begin_point) }.to raise_error(/must include one of begin_point/)
    end

    it 'raises an error when splits are out of order' do
      begin_point = lap_1_aid_2.time_point_in
      end_point = lap_1_aid_1.time_point_out
      begin_split = aid_2_split
      end_split = aid_1_split
      expect { Segment.new(begin_point: begin_point, end_point: end_point,
                           begin_split: begin_split, end_split: end_split) }
          .to raise_error(/Segment splits on the same lap are out of order/)
    end

    it 'raises an error when time_points are out of order' do
      begin_point = lap_1_aid_1.time_point_out
      end_point = lap_1_aid_1.time_point_in
      expect { Segment.new(begin_point: begin_point, end_point: end_point) }
          .to raise_error(/Segment bitkeys within the same split are out of order/)
    end

    it 'does not raise an error when splits are out of order if order_control: false is given' do
      begin_point = lap_1_aid_2.time_point_in
      end_point = lap_1_aid_1.time_point_out
      begin_split = aid_2_split
      end_split = aid_1_split
      expect { Segment.new(begin_point: begin_point, end_point: end_point,
                           begin_split: begin_split, end_split: end_split, order_control: false) }
          .not_to raise_error
    end
  end

  describe '#==' do
    # Allows a segment to be used as a hash key and matched with another hash key
    it 'should equate itself with other segments using the same splits' do
      segment1 = lap_1_start_to_lap_1_aid_1
      segment2 = lap_1_start_to_lap_1_aid_1_duplicate
      expect(segment1 == segment2).to eq(true)
    end

    it 'should not equate itself with other segments using different splits' do
      segment1 = lap_1_start_to_lap_1_aid_1
      segment2 = lap_1_start_to_lap_1_aid_2
      expect(segment1 == segment2).to eq(false)
    end
  end

  describe '#name' do
    it 'should return a "Time in" name if it is within a waypoint group' do
      expect(lap_1_in_aid_1.name).to eq('Time in Aid 1')
    end

    it 'should return a compound name if it is between waypoint groups' do
      expect(lap_1_start_to_lap_1_aid_1.name).to eq('Start Split to Aid 1')
      expect(lap_1_aid_2_to_lap_1_finish.name).to eq('Aid 2 to Finish Split')
    end

    it 'should return a single name if begin sub_split and end sub_split are the same' do
      expect(lap_1_start_to_lap_1_start.name).to eq('Start Split')
      expect(aid_1_in_to_aid_1_in.name).to eq('Aid 1 In')
    end
  end

  describe '#distance' do
    it 'should return zero distance for in_aid segments' do
      expect(lap_1_in_aid_1.distance).to eq(0)
      expect(lap_1_in_aid_2.distance).to eq(0)
      expect(lap_1_in_aid_3.distance).to eq(0)
    end

    it 'should calculate distance properly for single segments' do
      expect(lap_1_start_to_lap_1_aid_1.distance).to eq(10000)
      expect(lap_1_aid_1_to_lap_1_aid_2.distance).to eq(15000)
      expect(lap_1_aid_2_to_lap_1_aid_3.distance).to eq(20000)
      expect(lap_1_aid_3_to_lap_1_finish.distance).to eq(25000)
    end

    it 'should calculate distance properly for extended segments' do
      expect(lap_1_start_to_lap_1_aid_2.distance).to eq(25000)
      expect(lap_1_start_to_lap_1_aid_3.distance).to eq(45000)
      expect(lap_1_start_to_lap_1_finish.distance).to eq(70000)
      expect(lap_1_aid_1_to_lap_1_finish.distance).to eq(60000)
      expect(lap_1_aid_2_to_lap_1_finish.distance).to eq(45000)
    end

    it 'should return zero distance for segments with same start and end sub_split' do
      expect(aid_1_in_to_aid_1_in.distance).to eq(0)
    end

    it 'should calculate distance properly for unusual segments' do
      expect(lap_1_aid_1_to_lap_1_aid_2_inclusive.distance).to eq(15000)
    end
  end

  describe '#vert_gain' do
    it 'should return zero vert_gain for in_aid segments' do
      expect(lap_1_in_aid_1.vert_gain).to eq(0)
      expect(lap_1_in_aid_2.vert_gain).to eq(0)
      expect(lap_1_in_aid_3.vert_gain).to eq(0)
    end

    it 'should calculate vert_gain properly for single segments' do
      expect(lap_1_start_to_lap_1_aid_1.vert_gain).to eq(1000)
      expect(lap_1_aid_1_to_lap_1_aid_2.vert_gain).to eq(1500)
      expect(lap_1_aid_2_to_lap_1_aid_3.vert_gain).to eq(2000)
      expect(lap_1_aid_3_to_lap_1_finish.vert_gain).to eq(2500)
    end

    it 'should calculate vert_gain properly for extended segments' do
      expect(lap_1_start_to_lap_1_aid_2.vert_gain).to eq(2500)
      expect(lap_1_start_to_lap_1_aid_3.vert_gain).to eq(4500)
      expect(lap_1_start_to_lap_1_finish.vert_gain).to eq(7000)
      expect(lap_1_aid_1_to_lap_1_finish.vert_gain).to eq(6000)
      expect(lap_1_aid_2_to_lap_1_finish.vert_gain).to eq(4500)
    end

    it 'should return zero vert_gain for segments with same start and end sub_split' do
      expect(aid_1_in_to_aid_1_in.vert_gain).to eq(0)
    end

    it 'should calculate vert_gain properly for unusual segments' do
      expect(lap_1_aid_1_to_lap_1_aid_2_inclusive.vert_gain).to eq(1500)
    end
  end

  describe '#vert_loss' do
    it 'should return zero vert_loss for in_aid segments' do
      expect(lap_1_in_aid_1.vert_loss).to eq(0)
      expect(lap_1_in_aid_2.vert_loss).to eq(0)
      expect(lap_1_in_aid_3.vert_loss).to eq(0)
    end

    it 'should calculate vert_loss properly for single segments' do
      expect(lap_1_start_to_lap_1_aid_1.vert_loss).to eq(500)
      expect(lap_1_aid_1_to_lap_1_aid_2.vert_loss).to eq(750)
      expect(lap_1_aid_2_to_lap_1_aid_3.vert_loss).to eq(1000)
      expect(lap_1_aid_3_to_lap_1_finish.vert_loss).to eq(1250)
    end

    it 'should calculate vert_loss properly for extended segments' do
      expect(lap_1_start_to_lap_1_aid_2.vert_loss).to eq(1250)
      expect(lap_1_start_to_lap_1_aid_3.vert_loss).to eq(2250)
      expect(lap_1_start_to_lap_1_finish.vert_loss).to eq(3500)
      expect(lap_1_aid_1_to_lap_1_finish.vert_loss).to eq(3000)
      expect(lap_1_aid_2_to_lap_1_finish.vert_loss).to eq(2250)
    end

    it 'should return zero vert_loss for segments with same start and end sub_split' do
      expect(aid_1_in_to_aid_1_in.vert_loss).to eq(0)
    end

    it 'should calculate vert_loss properly for unusual segments' do
      expect(lap_1_aid_1_to_lap_1_aid_2_inclusive.vert_loss).to eq(750)
    end
  end

  describe '#full_course' do
    it 'should accurately report whether it represents an entire course' do
      expect(lap_1_start_to_lap_1_finish.full_course?).to eq(true)
      expect(lap_1_start_to_lap_1_aid_1.full_course?).to eq(false)
      expect(lap_1_in_aid_1.full_course?).to eq(false)
    end
  end

  describe '#special_limits_type' do
    it 'should return :start for a segment consisting of start split on lap 1 only' do
      expect(lap_1_start_to_lap_1_start.special_limits_type).to eq(:start)
      expect(lap_2_start_to_lap_2_start.special_limits_type).not_to eq(:start)
    end

    it 'should return :in_aid for an in-aid segment' do
      expect(lap_1_in_aid_1.special_limits_type).to eq(:in_aid)
    end

    it 'should return nil for segments between splits' do
      expect(lap_1_start_to_lap_1_aid_1.special_limits_type).to be_nil
      expect(lap_1_start_to_lap_1_finish.special_limits_type).to be_nil
      expect(lap_1_aid_1_to_lap_1_aid_2_inclusive.special_limits_type).to be_nil
    end
  end
end