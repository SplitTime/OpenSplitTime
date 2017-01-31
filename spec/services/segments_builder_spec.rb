require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe SegmentsBuilder do
  let(:test_event) { FactoryGirl.build_stubbed(:event_with_standard_splits, laps_required: 3, splits_count: 3) }

  describe '#initialize' do
    it 'initializes with a set of time_points in an args hash' do
      _, time_points = lap_splits_and_time_points(test_event)
      expect { SegmentsBuilder.new(time_points: time_points) }.not_to raise_error
    end

    it 'raises an error if initialized without lap_splits' do
      expect { SegmentsBuilder.new(random_param: 123) }.to raise_error(/must include time_points/)
    end

    it 'raises an error if initialized with any argument other than lap_splits' do
      _, time_points = lap_splits_and_time_points(test_event)
      expect { SegmentsBuilder.new(time_points: time_points, random_param: 123) }
          .to raise_error(/may not include random_param/)
    end
  end

  describe '#segments' do
    it 'returns an empty array if no time_points are provided' do
      builder = SegmentsBuilder.new(time_points: [])
      expect(builder.segments).to eq([])
    end

    it 'returns an array containing one fewer element than the time_points' do
      _, time_points = lap_splits_and_time_points(test_event)
      builder = SegmentsBuilder.new(time_points: time_points)
      expect(time_points.size).to eq(12)
      expect(builder.segments.size).to eq(11)
    end

    it 'returns segments having begin time_points equal to all time_points but the last' do
      _, time_points = lap_splits_and_time_points(test_event)
      builder = SegmentsBuilder.new(time_points: time_points)
      expect(builder.segments.map(&:begin_point)).to eq(time_points[0..-2])
    end

    it 'returns segments having end time_points equal to all provided time_points but the first' do
      _, time_points = lap_splits_and_time_points(test_event)
      builder = SegmentsBuilder.new(time_points: time_points)
      expect(builder.segments.map(&:end_point)).to eq(time_points[1..-1])
    end

    it 'returns segments with populated lap_splits if splits are provided' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      splits = lap_splits.map(&:split)
      builder = SegmentsBuilder.new(time_points: time_points, splits: splits)
      expect(builder.segments.first.begin_lap_split).to eq(lap_splits[0])
      expect(builder.segments.first.end_lap_split).to eq(lap_splits[1])
      expect(builder.segments.last.begin_lap_split).to eq(lap_splits[-2])
      expect(builder.segments.last.end_lap_split).to eq(lap_splits[-1])
    end
  end

  describe '#segments_with_zero_start' do
    it 'returns an empty array if no time_points are provided' do
      builder = SegmentsBuilder.new(time_points: [])
      expect(builder.segments_with_zero_start).to eq([])
    end

    it 'returns an array containing one fewer element than the time_points' do
      _, time_points = lap_splits_and_time_points(test_event)
      builder = SegmentsBuilder.new(time_points: time_points)
      expect(time_points.size).to eq(12)
      expect(builder.segments_with_zero_start.size).to eq(12)
    end

    it 'returns segments having begin time_points equal to the begin time_point plus all time_points but the last' do
      _, time_points = lap_splits_and_time_points(test_event)
      builder = SegmentsBuilder.new(time_points: time_points)
      expect(builder.segments_with_zero_start.map(&:begin_point)).to eq(time_points[0..0] + time_points[0..-2])
    end

    it 'returns segments having end time_points equal to all provided time_points' do
      _, time_points = lap_splits_and_time_points(test_event)
      builder = SegmentsBuilder.new(time_points: time_points)
      expect(builder.segments_with_zero_start.map(&:end_point)).to eq(time_points)
    end
  end
end