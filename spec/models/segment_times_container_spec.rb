require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe SegmentTimesContainer do
  let(:course) { FactoryGirl.build_stubbed(:course_with_standard_splits, splits_count: 3) }
  let(:start) { course.splits.first }
  let(:aid_1) { course.splits.second }
  let(:finish) { course.splits.last }
  let(:lap_1_zero_start) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                             end_lap: 1, end_split: start, end_in_out: 'in') }
  let(:lap_1_in_aid_1) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: aid_1, begin_in_out: 'in',
                                           end_lap: 1, end_split: aid_1, end_in_out: 'out') }
  let(:lap_1_aid_1_to_lap_1_finish) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: aid_1, begin_in_out: 'out',
                                                        end_lap: 1, end_split: finish, end_in_out: 'in') }
  let(:lap_1_start_to_lap_2_finish) { FactoryGirl.build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                                        end_lap: 2, end_split: finish, end_in_out: 'in') }
  let(:lap_2_finish_to_lap_1_start) { FactoryGirl.build(:segment, begin_lap: 2, begin_split: finish, begin_in_out: 'in',
                                                        end_lap: 1, end_split: start, end_in_out: 'in', order_control: false) }

  describe '#initialize' do
    it 'initializes with no arguments' do
      expect { SegmentTimesContainer.new }.not_to raise_error
    end

    it 'initializes with an args hash that contains only efforts' do
      efforts = FactoryGirl.build_stubbed_list(:effort, 4)
      expect { SegmentTimesContainer.new(efforts: efforts) }.not_to raise_error
    end

    it 'raises an ArgumentError if initialized with an args hash that contains an unknown parameter' do
      expect { SegmentTimesContainer.new(random_param: 123) }.to raise_error(/may not include random_param/)
    end

    it 'raises an ArgumentError if initialized with calc_model: :focused but without effort_ids' do
      expect { SegmentTimesContainer.new(calc_model: :focused) }.to raise_error(/cannot be initialized/)
    end

    it 'raises an ArgumentError if initialized with an unrecognized calc_model' do
      expect { SegmentTimesContainer.new(calc_model: :random) }.to raise_error(/calc_model random is not recognized/)
    end
  end

  describe '#segment_time' do
    it 'sends the correct message to SegmentTimeCalculator for a zero_start segment' do
      segment = lap_1_zero_start
      calc_model = :terrain
      expected = {segment: segment, effort_ids: nil, calc_model: calc_model}
      validate_segment_time(segment, calc_model, expected)
    end

    it 'sends the correct message to SegmentTimeCalculator for a segment on the same lap' do
      segment = lap_1_aid_1_to_lap_1_finish
      calc_model = :terrain
      expected = {segment: segment, effort_ids: nil, calc_model: calc_model}
      validate_segment_time(segment, calc_model, expected)
    end

    it 'sends the correct message to SegmentTimeCalculator for a segment between laps' do
      segment = lap_1_start_to_lap_2_finish
      calc_model = :terrain
      expected = {segment: segment, effort_ids: nil, calc_model: calc_model}
      validate_segment_time(segment, calc_model, expected)
    end

    it 'sends the correct message to SegmentTimeCalculator for a reversed segment' do
      segment = lap_2_finish_to_lap_1_start
      calc_model = :terrain
      expected = {segment: segment, effort_ids: nil, calc_model: calc_model}
      validate_segment_time(segment, calc_model, expected)
    end

    it 'sends the correct message using calc_model: :stats' do
      segment = lap_1_aid_1_to_lap_1_finish
      calc_model = :stats
      expected = {segment: segment, effort_ids: nil, calc_model: calc_model}
      validate_segment_time(segment, calc_model, expected)
    end

    it 'sends the correct message using calc_model: :focused' do
      segment = lap_1_aid_1_to_lap_1_finish
      calc_model = :focused
      effort_ids = [1, 2, 3]
      expected = {segment: segment, effort_ids: effort_ids, calc_model: calc_model}
      validate_segment_time(segment, calc_model, expected, effort_ids)
    end

    def validate_segment_time(segment, calc_model, expected, effort_ids = nil)
      allow(SegmentTimeCalculator).to receive(:typical_time)
      SegmentTimesContainer.new(calc_model: calc_model, effort_ids: effort_ids).segment_time(segment)
      expect(SegmentTimeCalculator).to have_received(:typical_time).with(expected)
    end
  end

  describe '#limits' do
    it 'sends the correct message to DataStatus for a zero_start segment' do
      segment = lap_1_zero_start
      expected_time = 0
      expected_limits_type = :zero_start
      validate_limits(segment, expected_time, expected_limits_type, :terrain)
    end

    it 'sends the correct message to DataStatus for a segment in aid' do
      segment = lap_1_in_aid_1
      expected_time = 0
      expected_limits_type = :in_aid
      validate_limits(segment, expected_time, expected_limits_type, :terrain)
    end

    it 'sends the correct message to DataStatus for a segment between laps' do
      segment = lap_1_start_to_lap_2_finish
      expected_time = 100_000
      expected_limits_type = :terrain
      validate_limits(segment, expected_time, expected_limits_type, :terrain)
    end

    it 'sends the correct message to DataStatus when calc_model is :stats' do
      segment = lap_1_start_to_lap_2_finish
      expected_time = 100_000
      expected_limits_type = :stats
      validate_limits(segment, expected_time, expected_limits_type, :stats)
    end

    it 'sends the correct message to DataStatus when calc_model is :focused' do
      segment = lap_1_start_to_lap_2_finish
      expected_time = 100_000
      expected_limits_type = :focused
      validate_limits(segment, expected_time, expected_limits_type, :focused)
    end

    it 'returns an empty hash if segment_time is not present' do
      segment = lap_1_start_to_lap_2_finish
      container = SegmentTimesContainer.new(calc_model: :terrain)
      allow(container).to receive(:segment_time).and_return(nil)
      expect(container.limits(segment)).to eq({})
    end

    def validate_limits(segment, expected_time, expected_limits_type, calc_model)
      allow(DataStatus).to receive(:limits)
      container = SegmentTimesContainer.new(calc_model: calc_model, effort_ids: [1,2,3])
      allow(container).to receive(:segment_time).and_return(expected_time)
      container.limits(segment)
      expect(DataStatus).to have_received(:limits).with(expected_time, expected_limits_type)
    end
  end

  describe '#data_status' do
    it 'sends the correct message to DataStatus for a zero_start segment' do
      segment = lap_1_zero_start
      time = 0
      limits = {low_bad: 0, low_questionable: 0, high_questionable: 0, high_bad: 0}
      validate_data_status(segment, time, limits, :terrain)
    end

    it 'sends the correct message to DataStatus for an inter-lap segment' do
      segment = lap_1_start_to_lap_2_finish
      time = 50_000
      limits = {low_bad: 30_000, low_questionable: 35_000, high_questionable: 60_000, high_bad: 80_000}
      validate_data_status(segment, time, limits, :terrain)
    end

    it 'returns nil if limits is not present' do
      segment = lap_1_start_to_lap_2_finish
      time = 0
      container = SegmentTimesContainer.new(calc_model: :terrain)
      allow(container).to receive(:limits).and_return({})
      expect(container.data_status(segment, time)).to eq(nil)
    end

    def validate_data_status(segment, time, limits, calc_model)
      allow(DataStatus).to receive(:determine)
      container = SegmentTimesContainer.new(calc_model: calc_model, effort_ids: [1,2,3])
      allow(container).to receive(:limits).and_return(limits)
      container.data_status(segment, time)
      expect(DataStatus).to have_received(:determine).with(limits, time)
    end
  end
end