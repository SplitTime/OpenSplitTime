require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe SegmentTimesPlanner do
  before do
    FactoryGirl.reload
  end

  let(:test_event) { FactoryGirl.build_stubbed(:event_with_standard_splits, splits_count: 6) }

  describe '#initialize' do
    it 'initializes with expected_time and lap_splits in an args hash' do
      expected_time = 1000
      lap_splits = lap_splits_and_time_points(test_event).first
      expect { SegmentTimesPlanner.new(expected_time: expected_time, lap_splits: lap_splits) }.not_to raise_error
    end

    it 'raises an ArgumentError if no lap_splits are given' do
      expected_time = 1000
      expect { SegmentTimesPlanner.new(expected_time: expected_time) }.to raise_error(/must include lap_splits/)
    end

    it 'raises an ArgumentError if no expected_time is given' do
      lap_splits = lap_splits_and_time_points(test_event).first
      expect { SegmentTimesPlanner.new(lap_splits: lap_splits) }.to raise_error(/must include expected_time/)
    end
  end

  describe '#times_from_start' do
    it 'returns nil when any expected segment time is nil' do
      expected_time = 4500
      lap_splits = lap_splits_and_time_points(test_event).first
      planner = SegmentTimesPlanner.new(expected_time: expected_time,
                                        lap_splits: lap_splits,
                                        calc_model: :terrain)
      allow(planner).to receive(:serial_times).and_return([0, nil, 1000])
      expect(planner.times_from_start).to be_nil
    end

    it 'returns a hash containing keys corresponding to the segments generated from lap_splits' do
      expected_time = 4000
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      planner = SegmentTimesPlanner.new(expected_time: expected_time,
                                        lap_splits: lap_splits,
                                        calc_model: :terrain)
      expect(planner.times_from_start.size).to eq(time_points.size)
      expect(planner.times_from_start.keys).to eq(time_points)
    end

    it 'returns values corresponding to the expected times from start when expected_time equals total segment times' do
      expected_time = 3000
      expected = [0, 600, 600, 1200, 1200, 1800, 1800, 2400, 2400, 3000]
      validate_times_from_start(expected_time, expected)
    end

    it 'returns values adjusted for pace when expected_time does not equal total segment times' do
      expected_time = 4500
      expected = [0, 900, 900, 1800, 1800, 2700, 2700, 3600, 3600, 4500]
      validate_times_from_start(expected_time, expected)
    end

    it 'performs no rounding when round_to is not provided' do
      expected_time = 4000
      expected = [0, 800, 800, 1600, 1600, 2400, 2400, 3200, 3200, 4000]
      validate_times_from_start(expected_time, expected)
    end

    it 'performs no rounding when round_to is zero' do
      expected_time = 4000
      round_to = 0
      expected = [0, 800, 800, 1600, 1600, 2400, 2400, 3200, 3200, 4000]
      validate_times_from_start(expected_time, expected, round_to)
    end

    it 'rounds to the nearest minute when round_to is 1.minute' do
      expected_time = 4000
      round_to = 1.minute
      expected = [0, 780, 780, 1620, 1620, 2400, 2400, 3180, 3180, 4020]
      validate_times_from_start(expected_time, expected, round_to)
    end

    it 'rounds to the nearest 10 minutes when round_to is 10.minute' do
      expected_time = 40000
      round_to = 10.minute
      expected = [0, 7800, 7800, 16200, 16200, 24000, 24000, 31800, 31800, 40200]
      validate_times_from_start(expected_time, expected, round_to)
    end

    it 'rounds to the nearest 30 seconds when round_to is 30.seconds' do
      expected_time = 4000
      round_to = 30.seconds
      expected = [0, 810, 810, 1590, 1590, 2400, 2400, 3210, 3210, 3990]
      validate_times_from_start(expected_time, expected, round_to)
    end

    def validate_times_from_start(expected_time, expected, round_to = nil)
      lap_splits = lap_splits_and_time_points(test_event).first
      planner = SegmentTimesPlanner.new(expected_time: expected_time,
                                        lap_splits: lap_splits,
                                        calc_model: :terrain)
      times = round_to ?
          planner.times_from_start(round_to: round_to).values :
          planner.times_from_start.values
      expect(times).to eq(expected)
    end
  end

  describe '#segment_times' do
    let(:round_to) { 0 } # This is required to avoid passing nil to #validate_segment_times

    it 'returns nil when any expected segment time is nil' do
      expected_time = 4500
      lap_splits = lap_splits_and_time_points(test_event).first
      planner = SegmentTimesPlanner.new(expected_time: expected_time,
                                        lap_splits: lap_splits,
                                        calc_model: :terrain)
      allow(planner).to receive(:serial_times).and_return([0, nil, 1000])
      expect(planner.segment_times).to be_nil
    end

    it 'returns a hash containing keys corresponding to the time_points generated from lap_splits' do
      expected_time = 4000
      lap_splits = lap_splits_and_time_points(test_event).first
      segments = SegmentsBuilder.segments_with_zero_start(lap_splits: lap_splits)
      planner = SegmentTimesPlanner.new(expected_time: expected_time,
                                        lap_splits: lap_splits,
                                        calc_model: :terrain)
      expect(planner.segment_times.size).to eq(segments.size)
      expect(planner.segment_times.keys).to eq(segments)
    end

    it 'returns values corresponding to the expected segment_times when expected_time equals total segment times' do
      expected_time = 3000
      expected = [0, 600, 0, 600, 0, 600, 0, 600, 0, 600]
      validate_segment_times(expected_time, expected)
    end

    it 'returns values adjusted for pace when expected_time does not equal total segment times' do
      expected_time = 4500
      expected = [0, 900, 0, 900, 0, 900, 0, 900, 0, 900]
      validate_segment_times(expected_time, expected)
    end

    it 'performs no rounding when round_to is not provided' do
      expected_time = 4000
      expected = [0, 800, 0, 800, 0, 800, 0, 800, 0, 800]
      validate_segment_times(expected_time, expected)
    end

    it 'performs no rounding when round_to is zero' do
      expected_time = 4000
      round_to = 0
      expected = [0, 800, 0, 800, 0, 800, 0, 800, 0, 800]
      validate_segment_times(expected_time, expected, round_to)
    end

    it 'rounds to the nearest minute when round_to is 1.minute' do
      expected_time = 4000
      round_to = 1.minute
      expected = [0, 780, 0, 780, 0, 780, 0, 780, 0, 780]
      validate_segment_times(expected_time, expected, round_to)
    end

    def validate_segment_times(expected_time, expected, round_to = nil)
      lap_splits = lap_splits_and_time_points(test_event).first
      planner = SegmentTimesPlanner.new(expected_time: expected_time,
                                        lap_splits: lap_splits,
                                        calc_model: :terrain)
      times = round_to ?
          planner.segment_times(round_to: round_to).values :
          planner.segment_times.values
      expect(times).to eq(expected)
    end
  end
end