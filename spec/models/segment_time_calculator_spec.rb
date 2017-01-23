require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe SegmentTimeCalculator do
  let(:start) { FactoryGirl.build_stubbed(:start_split, course_id: 10) }
  let(:aid_1) { FactoryGirl.build_stubbed(:split, base_name: 'Aid 1', course_id: 10, distance_from_start: 10000, vert_gain_from_start: 1000, vert_loss_from_start: 500) }
  let(:aid_2) { FactoryGirl.build_stubbed(:split, base_name: 'Aid 2', course_id: 10, distance_from_start: 25000, vert_gain_from_start: 2500, vert_loss_from_start: 1250) }
  let(:aid_3) { FactoryGirl.build_stubbed(:split, base_name: 'Aid 3', course_id: 10, distance_from_start: 45000, vert_gain_from_start: 4500, vert_loss_from_start: 2250) }
  let(:finish) { FactoryGirl.build_stubbed(:finish_split, course_id: 10, distance_from_start: 70000, vert_gain_from_start: 7000, vert_loss_from_start: 3500) }
  let(:lap_1_zero_start) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                             end_lap: 1, end_split: start, end_in_out: 'in') }
  let(:lap_1_start_to_lap_1_aid_1) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                                       end_lap: 1, end_split: aid_1, end_in_out: 'in') }
  let(:lap_1_aid_2_to_lap_1_aid_3) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: aid_2, begin_in_out: 'out',
                                                       end_lap: 1, end_split: aid_3, end_in_out: 'in') }
  let(:lap_1_start_to_lap_1_finish) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                                        end_lap: 1, end_split: finish, end_in_out: 'in') }
  let(:lap_1_start_to_lap_2_aid_1) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                                       end_lap: 2, end_split: aid_1, end_in_out: 'in') }
  let(:lap_1_start_to_lap_3_finish) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                                        end_lap: 3, end_split: finish, end_in_out: 'in') }
  let(:lap_1_in_aid_2) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: aid_2, begin_in_out: 'in',
                                           end_lap: 1, end_split: aid_2, end_in_out: 'out') }

  describe '#initialize' do
    it 'initializes with an args hash that contains only a calc_model and a segment' do
      expect { SegmentTimeCalculator.new(segment: lap_1_zero_start, calc_model: :terrain) }
          .not_to raise_error
    end

    it 'raises an ArgumentError if initialized without a calc_model' do
      expect { SegmentTimeCalculator.new(segment: lap_1_zero_start) }
          .to raise_error(/must include calc_model/)
    end

    it 'raises an ArgumentError if initialized without a segment' do
      expect { SegmentTimeCalculator.new(calc_model: :terrain) }
          .to raise_error(/must include segment/)
    end

    it 'raises an ArgumentError if initialized with calc_model: :focused but without effort_ids' do
      expect { SegmentTimeCalculator.new(segment: lap_1_zero_start, calc_model: :focused) }
          .to raise_error(/cannot be initialized/)
    end

    it 'raises an ArgumentError if initialized with an unrecognized calc_model' do
      expect { SegmentTimeCalculator.new(segment: lap_1_zero_start, calc_model: :random) }
          .to raise_error(/calc_model random is not recognized/)
    end
  end

  describe '#typical_time' do
    let(:distance_factor) { SegmentTimeCalculator::DISTANCE_FACTOR }
    let(:vert_gain_factor) { SegmentTimeCalculator::VERT_GAIN_FACTOR }

    it 'calculates a segment time in seconds using the specified calc_model' do
      segment = lap_1_start_to_lap_1_aid_1
      expected = 10000 * distance_factor + 1000 * vert_gain_factor
      validate_typical_time(segment, expected)
    end

    it 'returns zero for a segment that begins and ends with the lap 1 start split' do
      segment = lap_1_zero_start
      expected = 0
      validate_typical_time(segment, expected)
    end

    it 'returns typical time in aid for a segment that begins and ends within an intermediate split' do
      segment = lap_1_in_aid_2
      expected = 0
      validate_typical_time(segment, expected)
    end

    it 'returns typical time between splits for a segment that begins and ends with different intermediate splits' do
      segment = lap_1_aid_2_to_lap_1_aid_3
      expected = 20_000 * distance_factor + 2000 * vert_gain_factor
      validate_typical_time(segment, expected)
    end

    it 'returns typical time between splits for a segment made up of a complete lap' do
      segment = lap_1_start_to_lap_1_finish
      expected = 70_000 * distance_factor + 7_000 * vert_gain_factor
      validate_typical_time(segment, expected)
    end

    it 'returns typical time between splits for a segment that spans different laps' do
      segment = lap_1_start_to_lap_2_aid_1
      expected = 80_000 * distance_factor + 8000 * vert_gain_factor
      validate_typical_time(segment, expected)
    end

    it 'returns typical time between splits for a segment made up of multiple complete laps' do
      segment = lap_1_start_to_lap_3_finish
      expected = 210_000 * distance_factor + 21_000 * vert_gain_factor
      validate_typical_time(segment, expected)
    end
  end

  def validate_typical_time(segment, expected)
    course = FactoryGirl.build_stubbed(:course)
    allow(course).to receive(:distance).and_return(finish.distance_from_start)
    allow(course).to receive(:vert_gain).and_return(finish.vert_gain_from_start)
    allow(course).to receive(:vert_loss).and_return(finish.vert_loss_from_start)
    allow(segment.end_lap_split).to receive(:course).and_return(course)
    allow(segment.begin_lap_split).to receive(:course).and_return(course)
    calculator = SegmentTimeCalculator.new(segment: segment, calc_model: :terrain)
    expect(calculator.typical_time).to eq(expected)
  end
end