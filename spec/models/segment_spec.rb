require 'rails_helper'

RSpec.describe Segment, type: :model do
  let(:lap_1) { 1 }
  let(:lap_2) { 2 }
  let(:start) { FactoryGirl.build_stubbed(:start_split, course_id: 10) }
  let(:aid_1) { FactoryGirl.build_stubbed(:split, base_name: 'Aid 1', course_id: 10, distance_from_start: 10000, vert_gain_from_start: 1000, vert_loss_from_start: 500) }
  let(:aid_2) { FactoryGirl.build_stubbed(:split, base_name: 'Aid 2', course_id: 10, distance_from_start: 25000, vert_gain_from_start: 2500, vert_loss_from_start: 1250) }
  let(:aid_3) { FactoryGirl.build_stubbed(:split, base_name: 'Aid 3', course_id: 10, distance_from_start: 45000, vert_gain_from_start: 4500, vert_loss_from_start: 2250) }
  let(:finish) { FactoryGirl.build_stubbed(:finish_split, course_id: 10, distance_from_start: 70000, vert_gain_from_start: 7000, vert_loss_from_start: 3500) }
  let(:lap_1_start_to_lap_1_aid_1) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                                       end_lap: 1, end_split: aid_1, end_in_out: 'in') }
  let(:lap_1_start_to_lap_1_aid_2) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                                       end_lap: 1, end_split: aid_2, end_in_out: 'in') }
  let(:lap_1_start_to_lap_1_aid_3) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                                       end_lap: 1, end_split: aid_3, end_in_out: 'in') }
  let(:lap_1_start_to_lap_1_finish) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                                        end_lap: 1, end_split: finish, end_in_out: 'in') }
  let(:lap_1_aid_1_to_lap_1_aid_2) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: aid_1, begin_in_out: 'out',
                                                       end_lap: 1, end_split: aid_2, end_in_out: 'in') }
  let(:lap_1_aid_2_to_lap_1_aid_3) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: aid_2, begin_in_out: 'out',
                                                       end_lap: 1, end_split: aid_3, end_in_out: 'in') }
  let(:lap_1_aid_3_to_lap_1_finish) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: aid_3, begin_in_out: 'out',
                                                        end_lap: 1, end_split: finish, end_in_out: 'in') }
  let(:lap_1_aid_1_to_lap_1_finish) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: aid_1, begin_in_out: 'out',
                                                        end_lap: 1, end_split: finish, end_in_out: 'in') }
  let(:lap_1_aid_2_to_lap_1_finish) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: aid_2, begin_in_out: 'out',
                                                        end_lap: 1, end_split: finish, end_in_out: 'in') }
  let(:lap_1_in_aid_1) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: aid_1, begin_in_out: 'in',
                                           end_lap: 1, end_split: aid_1, end_in_out: 'out') }
  let(:lap_1_in_aid_2) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: aid_2, begin_in_out: 'in',
                                           end_lap: 1, end_split: aid_2, end_in_out: 'out') }
  let(:lap_1_in_aid_3) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: aid_3, begin_in_out: 'in',
                                           end_lap: 1, end_split: aid_3, end_in_out: 'out') }
  let(:lap_1_aid_1_to_lap_1_aid_2_inclusive) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: aid_1, begin_in_out: 'in',
                                                                 end_lap: 1, end_split: aid_2, end_in_out: 'out') }
  let(:lap_1_zero_start) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                             end_lap: 1, end_split: start, end_in_out: 'in') }
  let(:aid_1_in_to_aid_1_in) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: aid_1, begin_in_out: 'in',
                                                 end_lap: 1, end_split: aid_1, end_in_out: 'in') }
  let(:lap_2_zero_start) { FactoryGirl.build(:segment, begin_lap: 2, begin_split: start, begin_in_out: 'in',
                                             end_lap: 2, end_split: start, end_in_out: 'in') }
  let(:lap_1_start_to_lap_2_aid_1) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                                       end_lap: 2, end_split: aid_1, end_in_out: 'in') }
  let(:lap_1_start_to_lap_2_finish) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                                        end_lap: 2, end_split: finish, end_in_out: 'in') }
  let(:lap_1_finish_to_lap_2_start) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: finish, begin_in_out: 'in',
                                                        end_lap: 2, end_split: start, end_in_out: 'in') }

  describe 'initialization' do
    it 'initializes when given a begin_point and end_point in an args hash' do
      begin_point = LapSplit.new(lap_1, aid_1).time_point_in
      end_point = LapSplit.new(lap_1, aid_1).time_point_out
      expect { Segment.new(begin_point: begin_point, end_point: end_point) }
          .not_to raise_error
    end

    it 'raises an error if missing begin_point' do
      end_point = LapSplit.new(lap_1, aid_1).time_point_out
      expect { Segment.new(end_point: end_point) }
          .to raise_error(/must include one of begin_point and end_point or begin_sub_split and end_sub_split/)
    end

    it 'raises an error if missing end_point' do
      begin_point = LapSplit.new(lap_1, aid_1).time_point_in
      expect { Segment.new(begin_point: begin_point) }
          .to raise_error(/must include one of begin_point and end_point or begin_sub_split and end_sub_split/)
    end

    it 'raises an error when splits on the same lap are out of order' do
      begin_lap, begin_split, begin_in_out = lap_1, aid_2, 'in'
      end_lap, end_split, end_in_out = lap_1, aid_1, 'in'
      expect { FactoryGirl.build(:segment, begin_lap: begin_lap, begin_split: begin_split, begin_in_out: begin_in_out,
                                 end_lap: end_lap, end_split: end_split, end_in_out: end_in_out) }
          .to raise_error(/Segment splits on the same lap are out of order/)
    end

    it 'raises an error when laps are out of order' do
      begin_lap, begin_split, begin_in_out = lap_2, aid_1, 'in'
      end_lap, end_split, end_in_out = lap_1, aid_1, 'in'
      expect { FactoryGirl.build(:segment, begin_lap: begin_lap, begin_split: begin_split, begin_in_out: begin_in_out,
                                 end_lap: end_lap, end_split: end_split, end_in_out: end_in_out) }
          .to raise_error(/Segment laps are out of order/)
    end

    it 'raises an error when time_points are out of order' do
      begin_lap, begin_split, begin_in_out = lap_1, aid_1, 'out'
      end_lap, end_split, end_in_out = lap_1, aid_1, 'in'
      expect { FactoryGirl.build(:segment, begin_lap: begin_lap, begin_split: begin_split, begin_in_out: begin_in_out,
                                 end_lap: end_lap, end_split: end_split, end_in_out: end_in_out) }
          .to raise_error(/Segment bitkeys within the same split are out of order/)
    end

    it 'does not raise an error when splits are out of order if order_control: false is given' do
      begin_lap, begin_split, begin_in_out = lap_1, aid_2, 'in'
      end_lap, end_split, end_in_out = lap_1, aid_1, 'in'
      expect { FactoryGirl.build(:segment, begin_lap: begin_lap, begin_split: begin_split, begin_in_out: begin_in_out,
                                 end_lap: end_lap, end_split: end_split, end_in_out: end_in_out, order_control: false) }
          .not_to raise_error
    end
  end

  describe '#==' do
    # Allows a segment to be used as a hash key and matched with another hash key
    it 'equates itself with other segments using the same splits' do
      begin_lap, begin_split, begin_in_out = lap_1, aid_1, 'in'
      end_lap, end_split, end_in_out = lap_2, aid_2, 'in'
      segment1 = FactoryGirl.build(:segment, begin_lap: begin_lap, begin_split: begin_split, begin_in_out: begin_in_out,
                                   end_lap: end_lap, end_split: end_split, end_in_out: end_in_out)
      segment2 = FactoryGirl.build(:segment, begin_lap: begin_lap, begin_split: begin_split, begin_in_out: begin_in_out,
                                   end_lap: end_lap, end_split: end_split, end_in_out: end_in_out)
      expect(segment1 == segment2).to eq(true)
    end

    it 'does not equate itself with other segments using different splits' do
      begin_lap, begin_split, begin_in_out = lap_1, aid_1, 'in'
      end_lap, end_split, end_in_out = lap_2, aid_2, 'in'
      alt_end_lap, alt_end_split, alt_end_in_out = lap_2, aid_2, 'out'
      segment1 = FactoryGirl.build(:segment, begin_lap: begin_lap, begin_split: begin_split, begin_in_out: begin_in_out,
                                   end_lap: end_lap, end_split: end_split, end_in_out: end_in_out)
      segment2 = FactoryGirl.build(:segment, begin_lap: begin_lap, begin_split: begin_split, begin_in_out: begin_in_out,
                                   end_lap: alt_end_lap, end_split: alt_end_split, end_in_out: alt_end_in_out)
      expect(segment1 == segment2).to eq(false)
    end
  end

  describe '#name' do
    it 'returns a "Time in" name if it is within a waypoint group' do
      expect(lap_1_in_aid_1.name).to eq('Time in Aid 1')
    end

    it 'returns a compound name if it is between waypoint groups' do
      expect(lap_1_start_to_lap_1_aid_1.name).to eq('Start Split to Aid 1')
      expect(lap_1_aid_2_to_lap_1_finish.name).to eq('Aid 2 to Finish Split')
    end

    it 'returns a single name if begin sub_split and end sub_split are the same' do
      expect(lap_1_zero_start.name).to eq('Start Split')
      expect(aid_1_in_to_aid_1_in.name).to eq('Aid 1 In')
    end
  end

  describe '#distance' do
    it 'returns zero distance for in_aid segments' do
      validate_attribute(:distance, lap_1_in_aid_1, 0)
      validate_attribute(:distance, lap_1_in_aid_2, 0)
      validate_attribute(:distance, lap_1_in_aid_3, 0)
    end

    it 'calculates distance properly for single segments' do
      validate_attribute(:distance, lap_1_start_to_lap_1_aid_1, 10000)
      validate_attribute(:distance, lap_1_aid_1_to_lap_1_aid_2, 15000)
      validate_attribute(:distance, lap_1_aid_2_to_lap_1_aid_3, 20000)
      validate_attribute(:distance, lap_1_aid_3_to_lap_1_finish, 25000)
    end

    it 'calculates distance properly for extended segments' do
      validate_attribute(:distance, lap_1_start_to_lap_1_aid_2, 25000)
      validate_attribute(:distance, lap_1_start_to_lap_1_aid_3, 45000)
      validate_attribute(:distance, lap_1_start_to_lap_1_finish, 70000)
      validate_attribute(:distance, lap_1_aid_1_to_lap_1_finish, 60000)
      validate_attribute(:distance, lap_1_aid_2_to_lap_1_finish, 45000)
    end

    it 'returns zero distance for segments with same start and end sub_split' do
      validate_attribute(:distance, aid_1_in_to_aid_1_in, 0)
    end

    it 'calculates distance properly for unusual segments' do
      validate_attribute(:distance, lap_1_aid_1_to_lap_1_aid_2_inclusive, 15000)
    end

    it 'calculates distance properly between laps for completed laps' do
      validate_attribute(:distance, lap_1_start_to_lap_2_finish, 140000)
    end

    it 'calculates distance properly between laps for partially completed laps' do
      validate_attribute(:distance, lap_1_start_to_lap_2_aid_1, 80000)
    end
  end

  describe '#vert_gain' do
    it 'returns zero vert_gain for in_aid segments' do
      validate_attribute(:vert_gain, lap_1_in_aid_1, 0)
      validate_attribute(:vert_gain, lap_1_in_aid_2, 0)
      validate_attribute(:vert_gain, lap_1_in_aid_3, 0)
    end

    it 'calculates vert_gain properly for single segments' do
      validate_attribute(:vert_gain, lap_1_start_to_lap_1_aid_1, 1000)
      validate_attribute(:vert_gain, lap_1_aid_1_to_lap_1_aid_2, 1500)
      validate_attribute(:vert_gain, lap_1_aid_2_to_lap_1_aid_3, 2000)
      validate_attribute(:vert_gain, lap_1_aid_3_to_lap_1_finish, 2500)
    end

    it 'calculates vert_gain properly for extended segments' do
      validate_attribute(:vert_gain, lap_1_start_to_lap_1_aid_2, 2500)
      validate_attribute(:vert_gain, lap_1_start_to_lap_1_aid_3, 4500)
      validate_attribute(:vert_gain, lap_1_start_to_lap_1_finish, 7000)
      validate_attribute(:vert_gain, lap_1_aid_1_to_lap_1_finish, 6000)
      validate_attribute(:vert_gain, lap_1_aid_2_to_lap_1_finish, 4500)
    end

    it 'returns zero vert_gain for segments with same start and end sub_split' do
      validate_attribute(:vert_gain, aid_1_in_to_aid_1_in, 0)
    end

    it 'calculates vert_gain properly for unusual segments' do
      validate_attribute(:vert_gain, lap_1_aid_1_to_lap_1_aid_2_inclusive, 1500)
    end

    it 'calculates vert_gain properly between laps for completed laps' do
      validate_attribute(:vert_gain, lap_1_start_to_lap_2_finish, 14000)
    end

    it 'calculates vert_gain properly between laps for partially completed laps' do
      validate_attribute(:vert_gain, lap_1_start_to_lap_2_aid_1, 8000)
    end
  end

  describe '#vert_loss' do
    it 'returns zero vert_loss for in_aid segments' do
      validate_attribute(:vert_loss, lap_1_in_aid_1, 0)
      validate_attribute(:vert_loss, lap_1_in_aid_2, 0)
      validate_attribute(:vert_loss, lap_1_in_aid_3, 0)
    end

    it 'calculates vert_loss properly for single segments' do
      validate_attribute(:vert_loss, lap_1_start_to_lap_1_aid_1, 500)
      validate_attribute(:vert_loss, lap_1_aid_1_to_lap_1_aid_2, 750)
      validate_attribute(:vert_loss, lap_1_aid_2_to_lap_1_aid_3, 1000)
      validate_attribute(:vert_loss, lap_1_aid_3_to_lap_1_finish, 1250)
    end

    it 'calculates vert_loss properly for extended segments' do
      validate_attribute(:vert_loss, lap_1_start_to_lap_1_aid_2, 1250)
      validate_attribute(:vert_loss, lap_1_start_to_lap_1_aid_3, 2250)
      validate_attribute(:vert_loss, lap_1_start_to_lap_1_finish, 3500)
      validate_attribute(:vert_loss, lap_1_aid_1_to_lap_1_finish, 3000)
      validate_attribute(:vert_loss, lap_1_aid_2_to_lap_1_finish, 2250)
    end

    it 'returns zero vert_loss for segments with same start and end sub_split' do
      validate_attribute(:vert_loss, aid_1_in_to_aid_1_in, 0)
    end

    it 'calculates vert_loss properly for unusual segments' do
      validate_attribute(:vert_loss, lap_1_aid_1_to_lap_1_aid_2_inclusive, 750)
    end

    it 'calculates vert_loss properly between laps for completed laps' do
      validate_attribute(:vert_loss, lap_1_start_to_lap_2_finish, 7000)
    end

    it 'calculates vert_loss properly between laps for partially completed laps' do
      validate_attribute(:vert_loss, lap_1_start_to_lap_2_aid_1, 4000)
    end
  end

  describe '#full_course' do
    it 'accurately reports whether it represents an entire course' do
      expect(lap_1_start_to_lap_1_finish.full_course?).to eq(true)
      expect(lap_1_start_to_lap_1_aid_1.full_course?).to eq(false)
      expect(lap_1_in_aid_1.full_course?).to eq(false)
    end
  end

  describe '#special_limits_type' do
    it 'returns :start for a segment consisting of start split on lap 1 only' do
      expect(lap_1_zero_start.special_limits_type).to eq(:zero_start)
      expect(lap_2_zero_start.special_limits_type).not_to eq(:zero_start)
    end

    it 'returns :in_aid for an in-aid segment' do
      expect(lap_1_in_aid_1.special_limits_type).to eq(:in_aid)
    end

    it 'returns :in_aid for a segment between laps' do
      expect(lap_1_finish_to_lap_2_start.special_limits_type).to eq(:in_aid)
    end

    it 'returns nil for segments between splits' do
      expect(lap_1_start_to_lap_1_aid_1.special_limits_type).to be_nil
      expect(lap_1_start_to_lap_1_finish.special_limits_type).to be_nil
      expect(lap_1_aid_1_to_lap_1_aid_2_inclusive.special_limits_type).to be_nil
    end
  end

  def validate_attribute(attribute, segment, expected)
    course = FactoryGirl.build_stubbed(:course)
    allow(course).to receive(:distance).and_return(finish.distance_from_start)
    allow(course).to receive(:vert_gain).and_return(finish.vert_gain_from_start)
    allow(course).to receive(:vert_loss).and_return(finish.vert_loss_from_start)
    allow(segment.end_lap_split).to receive(:course).and_return(course)
    allow(segment.begin_lap_split).to receive(:course).and_return(course)
    expect(segment.send(attribute)).to eq(expected)
  end
end