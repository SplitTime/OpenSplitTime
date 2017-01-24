require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe SegmentTimesPlanner do
  before do
    FactoryGirl.reload
  end

  let(:test_event) { FactoryGirl.build_stubbed(:event_functional, laps_required: 2, splits_count: 4, efforts_count: 1) }
  let(:test_effort) { test_event.efforts.first }
  let(:test_split_times) { test_effort.split_times }
  let(:start) { test_event.splits.first }
  let(:aid_1) { test_event.splits.second }
  let(:aid_2) { test_event.splits.third }
  let(:finish) { test_event.splits.last }
  let(:laps_required) { test_event.laps_required }

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
      course = test_event.course
      allow(course).to receive(:distance).and_return(finish.distance_from_start)
      allow(course).to receive(:vert_gain).and_return(finish.vert_gain_from_start)
      allow(course).to receive(:vert_loss).and_return(finish.vert_loss_from_start)
      serial_segments = SegmentsBuilder.segments_with_zero_start(lap_splits: lap_splits)
      serial_segments.each do |segment|
        [segment.begin_lap_split, segment.end_lap_split]
            .each { |lap_split| allow(lap_split).to receive(:course).and_return(course) }
      end
      planner = SegmentTimesPlanner.new(expected_time: expected_time,
                                        lap_splits: lap_splits,
                                        calc_model: :terrain,
                                        serial_segments: serial_segments)
      allow(planner).to receive(:serial_segments).and_return(serial_segments)
      expect(planner.times_from_start.size).to eq(time_points.size)
      expect(planner.times_from_start.keys).to eq(time_points)
    end

    it 'returns values corresponding to the expected times from start when expected_time equals total segment times' do
      expected_time = 3000
      expected = [0, 500, 500, 1000, 1000, 1500, 1500, 2000, 2000, 2500, 2500, 3000]
      validate_times_from_start(expected_time, expected)
    end

    it 'returns values adjusted for pace when expected_time does not equal total segment times' do
      expected_time = 4500
      expected = [0, 750, 750, 1500, 1500, 2250, 2250, 3000, 3000, 3750, 3750, 4500]
      validate_times_from_start(expected_time, expected)
    end

    it 'performs no rounding when round_to is not provided' do
      expected_time = 4000
      expected = [0, 667, 667, 1333, 1333, 2000, 2000, 2667, 2667, 3333, 3333, 4000]
      validate_times_from_start(expected_time, expected)
    end

    it 'performs no rounding when round_to is zero' do
      expected_time = 4000
      round_to = 0
      expected = [0, 667, 667, 1333, 1333, 2000, 2000, 2667, 2667, 3333, 3333, 4000]
      validate_times_from_start(expected_time, expected, round_to)
    end

    it 'rounds to the nearest minute when round_to is 1.minute' do
      expected_time = 4000
      round_to = 1.minute
      expected = [0, 660, 660, 1320, 1320, 1980, 1980, 2640, 2640, 3360, 3360, 4020]
      validate_times_from_start(expected_time, expected, round_to)
    end

    it 'rounds to the nearest 10 minutes when round_to is 10.minute' do
      expected_time = 40000
      round_to = 10.minute
      expected = [0, 6600, 6600, 13200, 13200, 19800, 19800, 26400, 26400, 33600, 33600, 40200]
      validate_times_from_start(expected_time, expected, round_to)
    end

    it 'rounds to the nearest 30 seconds when round_to is 30.seconds' do
      expected_time = 4000
      round_to = 30.seconds
      expected = [0, 660, 660, 1320, 1320, 2010, 2010, 2670, 2670, 3330, 3330, 3990]
      validate_times_from_start(expected_time, expected, round_to)
    end

    def validate_times_from_start(expected_time, expected, round_to = nil)
      lap_splits = lap_splits_and_time_points(test_event).first
      course = test_event.course
      allow(course).to receive(:distance).and_return(finish.distance_from_start)
      allow(course).to receive(:vert_gain).and_return(finish.vert_gain_from_start)
      allow(course).to receive(:vert_loss).and_return(finish.vert_loss_from_start)
      serial_segments = SegmentsBuilder.segments_with_zero_start(lap_splits: lap_splits)
      serial_segments.each do |segment|
        [segment.begin_lap_split, segment.end_lap_split]
            .each { |lap_split| allow(lap_split).to receive(:course).and_return(course) }
      end
      planner = SegmentTimesPlanner.new(expected_time: expected_time,
                                        lap_splits: lap_splits,
                                        calc_model: :terrain,
                                        serial_segments: serial_segments)
      allow(planner).to receive(:serial_segments).and_return(serial_segments)
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
      course = test_event.course
      allow(course).to receive(:distance).and_return(finish.distance_from_start)
      allow(course).to receive(:vert_gain).and_return(finish.vert_gain_from_start)
      allow(course).to receive(:vert_loss).and_return(finish.vert_loss_from_start)
      serial_segments = SegmentsBuilder.segments_with_zero_start(lap_splits: lap_splits)
      serial_segments.each do |segment|
        [segment.begin_lap_split, segment.end_lap_split]
            .each { |lap_split| allow(lap_split).to receive(:course).and_return(course) }
      end
      planner = SegmentTimesPlanner.new(expected_time: expected_time,
                                        lap_splits: lap_splits,
                                        calc_model: :terrain,
                                        serial_segments: serial_segments)
      allow(planner).to receive(:serial_segments).and_return(serial_segments)
      expect(planner.segment_times.size).to eq(serial_segments.size)
      expect(planner.segment_times.keys).to eq(serial_segments)
    end

    it 'returns values corresponding to the expected segment_times when expected_time equals total segment times' do
      expected_time = 3000
      expected = [0, 500, 0, 500, 0, 500, 0, 500, 0, 500, 0, 500]
      validate_segment_times(expected_time, expected)
    end

    it 'returns values adjusted for pace when expected_time does not equal total segment times' do
      expected_time = 4500
      expected = [0, 750, 0, 750, 0, 750, 0, 750, 0, 750, 0, 750]
      validate_segment_times(expected_time, expected)
    end

    it 'performs no rounding when round_to is not provided' do
      expected_time = 4000
      expected = [0, 667, 0, 667, 0, 667, 0, 667, 0, 667, 0, 667]
      validate_segment_times(expected_time, expected)
    end

    it 'performs no rounding when round_to is zero' do
      expected_time = 4000
      round_to = 0
      expected = [0, 667, 0, 667, 0, 667, 0, 667, 0, 667, 0, 667]
      validate_segment_times(expected_time, expected, round_to)
    end

    it 'rounds to the nearest minute when round_to is 1.minute' do
      expected_time = 4000
      round_to = 1.minute
      expected = [0, 660, 0, 660, 0, 660, 0, 660, 0, 660, 0, 660]
      validate_segment_times(expected_time, expected, round_to)
    end

    def validate_segment_times(expected_time, expected, round_to = nil)
      lap_splits = lap_splits_and_time_points(test_event).first
      course = test_event.course
      allow(course).to receive(:distance).and_return(finish.distance_from_start)
      allow(course).to receive(:vert_gain).and_return(finish.vert_gain_from_start)
      allow(course).to receive(:vert_loss).and_return(finish.vert_loss_from_start)
      serial_segments = SegmentsBuilder.segments_with_zero_start(lap_splits: lap_splits)
      serial_segments.each do |segment|
        [segment.begin_lap_split, segment.end_lap_split]
            .each { |lap_split| allow(lap_split).to receive(:course).and_return(course) }
      end
      planner = SegmentTimesPlanner.new(expected_time: expected_time,
                                        lap_splits: lap_splits,
                                        calc_model: :terrain,
                                        serial_segments: serial_segments)
      allow(planner).to receive(:serial_segments).and_return(serial_segments)
      times = round_to ?
          planner.segment_times(round_to: round_to).values :
          planner.segment_times.values
      expect(times).to eq(expected)
    end
  end
end