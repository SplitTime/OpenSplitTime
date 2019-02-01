# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SegmentsBuilder do
  subject(:builder) { SegmentsBuilder.new(time_points: time_points, splits: splits) }
  let(:event) { events(:rufa_2017_24h) }
  let(:time_points) { event.required_time_points }
  let(:lap_splits) { event.required_lap_splits }
  let(:splits) { nil }
  before { event.update(laps_required: 3) }

  describe '#initialize' do
    it 'initializes with a set of time_points in an args hash' do
      expect { SegmentsBuilder.new(time_points: time_points) }.not_to raise_error
    end

    it 'raises an error if initialized without lap_splits' do
      expect { SegmentsBuilder.new(random_param: 123) }.to raise_error(/must include time_points/)
    end

    it 'raises an error if initialized with any argument other than lap_splits' do
      expect { SegmentsBuilder.new(time_points: time_points, random_param: 123) }
          .to raise_error(/may not include random_param/)
    end
  end

  describe '#segments' do
    context 'if no time_points are provided' do
      let(:time_points) { [] }

      it 'returns an empty array' do
        expect(builder.segments).to eq([])
      end
    end

    context 'when time_points are provided' do
      it 'returns an array containing one fewer element than the time_points' do
        expect(time_points.size).to eq(9)
        expect(builder.segments.size).to eq(8)
      end

      it 'returns segments having begin time_points equal to all time_points but the last' do
        expect(builder.segments.map(&:begin_point)).to eq(time_points[0..-2])
      end

      it 'returns segments having end time_points equal to all provided time_points but the first' do
        expect(builder.segments.map(&:end_point)).to eq(time_points[1..-1])
      end
    end

    context 'when splits are provided' do
      let(:splits) { lap_splits.map(&:split) }

      it 'returns segments with populated lap_splits if splits are provided' do
        expect(builder.segments.first.begin_lap_split).to eq(lap_splits[0])
        expect(builder.segments.first.end_lap_split).to eq(lap_splits[1])
        expect(builder.segments.last.begin_lap_split).to eq(lap_splits[-2])
        expect(builder.segments.last.end_lap_split).to eq(lap_splits[-1])
      end
    end
  end

  describe '#segments_with_zero_start' do
    context 'if no time_points are provided' do
      let(:time_points) { [] }

      it 'returns an empty array' do
        expect(builder.segments_with_zero_start).to eq([])
      end
    end

    context 'when time_points are provided' do
      it 'returns an array containing the same number of elements as the time_points' do
        expect(time_points.size).to eq(9)
        expect(builder.segments_with_zero_start.size).to eq(9)
      end

      it 'returns segments having begin time_points equal to the begin time_point plus all time_points but the last' do
        expect(builder.segments_with_zero_start.map(&:begin_point)).to eq([time_points.first] + time_points[0..-2])
      end

      it 'returns segments having end time_points equal to all provided time_points' do
        expect(builder.segments_with_zero_start.map(&:end_point)).to eq(time_points)
      end
    end
  end
end
