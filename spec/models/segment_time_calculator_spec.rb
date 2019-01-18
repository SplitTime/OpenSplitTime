# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SegmentTimeCalculator do
  let(:stat_threshold) { SegmentTimeCalculator::STATS_CALC_THRESHOLD }
  let(:start) { build_stubbed(:split, :start, course_id: 10) }
  let(:aid_1) { build_stubbed(:split, base_name: 'Aid 1', course_id: 10, distance_from_start: 10000, vert_gain_from_start: 1000, vert_loss_from_start: 500) }
  let(:aid_2) { build_stubbed(:split, base_name: 'Aid 2', course_id: 10, distance_from_start: 25000, vert_gain_from_start: 2500, vert_loss_from_start: 1250) }
  let(:aid_3) { build_stubbed(:split, base_name: 'Aid 3', course_id: 10, distance_from_start: 45000, vert_gain_from_start: 4500, vert_loss_from_start: 2250) }
  let(:finish) { build_stubbed(:split, :finish, course_id: 10, distance_from_start: 70000, vert_gain_from_start: 7000, vert_loss_from_start: 3500) }
  let(:lap_1_zero_start) { build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                             end_lap: 1, end_split: start, end_in_out: 'in') }
  let(:lap_1_start_to_lap_1_aid_1) { build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                                       end_lap: 1, end_split: aid_1, end_in_out: 'in') }
  let(:lap_1_aid_2_to_lap_1_aid_3) { build(:segment, begin_lap: 1, begin_split: aid_2, begin_in_out: 'out',
                                                       end_lap: 1, end_split: aid_3, end_in_out: 'in') }
  let(:lap_1_start_to_lap_1_finish) { build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                                        end_lap: 1, end_split: finish, end_in_out: 'in') }
  let(:lap_1_start_to_lap_2_aid_1) { build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                                       end_lap: 2, end_split: aid_1, end_in_out: 'in') }
  let(:lap_1_start_to_lap_3_finish) { build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                                        end_lap: 3, end_split: finish, end_in_out: 'in') }
  let(:lap_1_in_aid_2) { build(:segment, begin_lap: 1, begin_split: aid_2, begin_in_out: 'in',
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

  describe '#typical_time (terrain)' do
    let(:distance_factor) { SegmentTimeCalculator::DISTANCE_FACTOR }
    let(:vert_gain_factor) { SegmentTimeCalculator::UP_VERT_GAIN_FACTOR }

    it 'calculates a segment time in seconds using the specified calc_model' do
      segment = lap_1_start_to_lap_1_aid_1
      expected = 10000 * distance_factor + 1000 * vert_gain_factor
      validate_typical_time_terrain(segment, expected)
    end

    it 'returns zero for a segment that begins and ends with the lap 1 start split' do
      segment = lap_1_zero_start
      expected = 0
      validate_typical_time_terrain(segment, expected)
    end

    it 'returns typical time in aid for a segment that begins and ends within an intermediate split' do
      segment = lap_1_in_aid_2
      expected = 0
      validate_typical_time_terrain(segment, expected)
    end

    it 'returns typical time between splits for a segment that begins and ends with different intermediate splits' do
      segment = lap_1_aid_2_to_lap_1_aid_3
      expected = 20_000 * distance_factor + 2000 * vert_gain_factor
      validate_typical_time_terrain(segment, expected)
    end

    it 'returns typical time between splits for a segment made up of a complete lap' do
      segment = lap_1_start_to_lap_1_finish
      expected = 70_000 * distance_factor + 7_000 * vert_gain_factor
      validate_typical_time_terrain(segment, expected)
    end

    it 'returns typical time between splits for a segment that spans different laps' do
      segment = lap_1_start_to_lap_2_aid_1
      expected = 80_000 * distance_factor + 8000 * vert_gain_factor
      validate_typical_time_terrain(segment, expected)
    end

    it 'returns typical time between splits for a segment made up of multiple complete laps' do
      segment = lap_1_start_to_lap_3_finish
      expected = 210_000 * distance_factor + 21_000 * vert_gain_factor
      validate_typical_time_terrain(segment, expected)
    end

    def validate_typical_time_terrain(segment, expected)
      course = build_stubbed(:course)
      allow(course).to receive(:distance).and_return(finish.distance_from_start)
      allow(course).to receive(:vert_gain).and_return(finish.vert_gain_from_start)
      allow(course).to receive(:vert_loss).and_return(finish.vert_loss_from_start)
      allow(segment.end_lap_split).to receive(:course).and_return(course)
      allow(segment.begin_lap_split).to receive(:course).and_return(course)
      calculator = SegmentTimeCalculator.new(segment: segment, calc_model: :terrain)
      expect(calculator.typical_time).to eq(expected)
    end
  end

  describe '#typical_time (stats)' do
    it 'sends :typical_segment_time to SplitTimeQuery with segment as a parameter' do
      segment = lap_1_start_to_lap_1_aid_1
      time_result = 100
      count_result = 10
      typical_time_stats(segment, time_result, count_result)
      expect(SplitTimeQuery).to have_received(:typical_segment_time).with(segment, nil)
    end

    it 'returns the time result if count result is at or above the stat threshold' do
      segment = lap_1_start_to_lap_1_aid_1
      time_result = 100
      count_result = stat_threshold
      time = typical_time_stats(segment, time_result, count_result)
      expect(time).to eq(time_result)
    end

    it 'returns nil if count result is below the stat threshold' do
      segment = lap_1_start_to_lap_1_aid_1
      time_result = 100
      count_result = stat_threshold - 1
      time = typical_time_stats(segment, time_result, count_result)
      expect(time).to be_nil
    end

    def typical_time_stats(segment, time_result, count_result)
      calculator = SegmentTimeCalculator.new(segment: segment, calc_model: :stats)
      allow(SplitTimeQuery).to receive(:typical_segment_time).and_return({'effort_count' => count_result, 'average' => time_result}.with_indifferent_access)
      calculator.typical_time
    end
  end

  describe '#typical_time (focused)' do
    it 'sends :typical_segment_time to SplitTimeQuery with segment and effort_ids as parameters' do
      segment = lap_1_start_to_lap_1_aid_1
      time_result = 100
      count_result = 10
      effort_ids = [1, 2, 3]
      typical_time_focused(segment, time_result, count_result, effort_ids)
      expect(SplitTimeQuery).to have_received(:typical_segment_time).with(segment, effort_ids)
    end

    it 'returns the time result if count result is at or above the stat threshold and effort_ids is present' do
      segment = lap_1_start_to_lap_1_aid_1
      time_result = 100
      count_result = stat_threshold
      effort_ids = [1, 2, 3]
      time = typical_time_focused(segment, time_result, count_result, effort_ids)
      expect(time).to eq(time_result)
    end

    it 'returns nil if count result is below the stat threshold' do
      segment = lap_1_start_to_lap_1_aid_1
      time_result = 100
      count_result = stat_threshold - 1
      effort_ids = [1, 2, 3]
      time = typical_time_focused(segment, time_result, count_result, effort_ids)
      expect(time).to be_nil
    end

    it 'returns nil if effort_ids are an empty array' do
      segment = lap_1_start_to_lap_1_aid_1
      time_result = 100
      count_result = stat_threshold - 1
      effort_ids = []
      time = typical_time_focused(segment, time_result, count_result, effort_ids)
      expect(time).to be_nil
    end

    def typical_time_focused(segment, time_result, count_result, effort_ids)
      calculator = SegmentTimeCalculator.new(segment: segment, calc_model: :focused, effort_ids: effort_ids)
      allow(SplitTimeQuery).to receive(:typical_segment_time).and_return({'effort_count' => count_result, 'average' => time_result}.with_indifferent_access)
      calculator.typical_time
    end
  end
end
