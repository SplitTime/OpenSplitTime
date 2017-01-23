require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe SegmentsBuilder do
  let(:test_event) { FactoryGirl.build_stubbed(:event_with_standard_splits, laps_required: 3, splits_count: 3) }

  describe '#initialize' do
    it 'initializes with a set of lap_splits in an args hash' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      expect { SegmentsBuilder.new(lap_splits: lap_splits) }.not_to raise_error
    end

    it 'raises an error if initialized without lap_splits' do
      expect { SegmentsBuilder.new(random_param: 123) }.to raise_error(/must include lap_splits/)
    end
  end

  describe '#segments' do
    it 'returns an empty array if no lap_splits are provided' do
      builder = SegmentsBuilder.new(lap_splits: [])
      expect(builder.segments).to eq([])
    end

    it 'returns an array containing one fewer element than the time_points derived from lap_splits' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      builder = SegmentsBuilder.new(lap_splits: lap_splits)
      expect(time_points.size).to eq(12)
      expect(builder.segments.size).to eq(11)
    end

    it 'returns segments having begin time_points equal to all time_points but the last' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      builder = SegmentsBuilder.new(lap_splits: lap_splits)
      expect(builder.segments.map(&:begin_point)).to eq(time_points[0..-2])
    end

    it 'returns segments having end time_points equal to all provided time_points but the first' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      builder = SegmentsBuilder.new(lap_splits: lap_splits)
      expect(builder.segments.map(&:end_point)).to eq(time_points[1..-1])
    end
  end

  describe '#segments_with_zero_start' do
    it 'returns an empty array if no lap_splits are provided' do
      builder = SegmentsBuilder.new(lap_splits: [])
      expect(builder.segments_with_zero_start).to eq([])
    end

    it 'returns an array containing one fewer element than the time_points derived from lap_splits' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      builder = SegmentsBuilder.new(lap_splits: lap_splits)
      expect(time_points.size).to eq(12)
      expect(builder.segments_with_zero_start.size).to eq(12)
    end

    it 'returns segments having begin time_points equal to the begin time_point plus all time_points but the last' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      builder = SegmentsBuilder.new(lap_splits: lap_splits)
      expect(builder.segments_with_zero_start.map(&:begin_point)).to eq(time_points[0..0] + time_points[0..-2])
    end

    it 'returns segments having end time_points equal to all provided time_points' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      builder = SegmentsBuilder.new(lap_splits: lap_splits)
      expect(builder.segments_with_zero_start.map(&:end_point)).to eq(time_points)
    end
  end
end