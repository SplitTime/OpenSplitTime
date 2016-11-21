require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe TerrainTimesCalculator do
  let(:split_times_101) { FactoryGirl.build_stubbed_list(:split_times_in_out, 20, effort_id: 101).first(10) }
  let(:split_ids) { split_times_101.map(&:split_id).uniq }
  let(:split1) { FactoryGirl.build_stubbed(:start_split, id: split_ids[0], course_id: 10, distance_from_start: 0) }
  let(:split2) { FactoryGirl.build_stubbed(:split, id: split_ids[1], course_id: 10, distance_from_start: 10000) }
  let(:split3) { FactoryGirl.build_stubbed(:split, id: split_ids[2], course_id: 10, distance_from_start: 20000) }
  let(:split4) { FactoryGirl.build_stubbed(:split, id: split_ids[3], course_id: 10, distance_from_start: 30000) }
  let(:split5) { FactoryGirl.build_stubbed(:split, id: split_ids[4], course_id: 10, distance_from_start: 40000) }
  let(:split6) { FactoryGirl.build_stubbed(:finish_split, id: split_ids[5], course_id: 10, distance_from_start: 50000) }

  describe '#initialize' do
    it 'initializes with a set of ordered_splits in an args hash' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      expect { TerrainTimesCalculator.new(ordered_splits: ordered_splits) }.not_to raise_error
    end

    it 'initializes with a set of ordered sub_splits and ordered_splits in an args hash' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      sub_splits = ordered_splits.map { |split| split.sub_splits }.flatten
      expect { TerrainTimesCalculator.new(sub_splits: sub_splits, ordered_splits: ordered_splits) }.not_to raise_error
    end

    it 'permits (but ignores) an efforts argument provided in the args hash' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      sub_splits = ordered_splits.map { |split| split.sub_splits }.flatten
      efforts = FactoryGirl.build_stubbed_list(:effort, 2)
      expect { TerrainTimesCalculator.new(sub_splits: sub_splits, ordered_splits: ordered_splits, efforts: efforts) }
          .not_to raise_error
    end

    it 'raises an error if initialized without a sub_splits or ordered_splits argument' do
      expect { TerrainTimesCalculator.new(random_param: 123) }.to raise_error(/must include one of/)
    end
  end

  describe '#times_from_start' do
    it 'returns an empty hash if no sub_splits are provided' do
      times_calculator = TerrainTimesCalculator.new(sub_splits: [])
      expect(times_calculator.times_from_start).to eq({})
    end

    it 'returns a hash containing the same number of elements as the sub_splits provided' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      sub_splits = ordered_splits.map { |split| split.sub_splits }.flatten
      times_calculator = TerrainTimesCalculator.new(sub_splits: sub_splits, ordered_splits: ordered_splits)
      expect(times_calculator.times_from_start.count).to eq(10)
    end

    it 'returns a hash whose keys are the same as those of the sub_splits provided' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      sub_splits = ordered_splits.map { |split| split.sub_splits }.flatten
      times_calculator = TerrainTimesCalculator.new(sub_splits: sub_splits, ordered_splits: ordered_splits)
      expect(times_calculator.times_from_start.keys).to eq(sub_splits)
    end

    it 'returns a value of zero for the start sub_split' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      sub_splits = ordered_splits.map { |split| split.sub_splits }.flatten
      start_sub_split = sub_splits.first
      times_calculator = TerrainTimesCalculator.new(sub_splits: sub_splits, ordered_splits: ordered_splits)
      expect(times_calculator.times_from_start[start_sub_split]).to eq(0)
    end

    it 'returns elapsed time in seconds based on calculated distance and vertical gain factors for all sub_splits' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      sub_splits = ordered_splits.map { |split| split.sub_splits }.flatten
      times_calculator = TerrainTimesCalculator.new(sub_splits: sub_splits, ordered_splits: ordered_splits)
      expect(times_calculator.times_from_start[sub_splits[1]]).to eq(split2.distance_from_start * DISTANCE_FACTOR)
      expect(times_calculator.times_from_start[sub_splits[2]]).to eq(split2.distance_from_start * DISTANCE_FACTOR)
      expect(times_calculator.times_from_start[sub_splits[3]]).to eq(split3.distance_from_start * DISTANCE_FACTOR)
      expect(times_calculator.times_from_start[sub_splits[4]]).to eq(split3.distance_from_start * DISTANCE_FACTOR)
      expect(times_calculator.times_from_start[sub_splits[5]]).to eq(split4.distance_from_start * DISTANCE_FACTOR)
      expect(times_calculator.times_from_start[sub_splits[6]]).to eq(split4.distance_from_start * DISTANCE_FACTOR)
      expect(times_calculator.times_from_start[sub_splits[7]]).to eq(split5.distance_from_start * DISTANCE_FACTOR)
      expect(times_calculator.times_from_start[sub_splits[8]]).to eq(split5.distance_from_start * DISTANCE_FACTOR)
      expect(times_calculator.times_from_start[sub_splits[9]]).to eq(split6.distance_from_start * DISTANCE_FACTOR)
    end
  end

  describe '#segment_time' do
    it 'returns elapsed time in seconds between begin and end of the provided segment' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      segment = Segment.new(split2.sub_splits.last, split3.sub_splits.first, split2, split3)
      sub_splits = ordered_splits.map { |split| split.sub_splits }.flatten
      times_calculator = TerrainTimesCalculator.new(sub_splits: sub_splits, ordered_splits: ordered_splits)
      expect(times_calculator.segment_time(segment))
          .to eq((split3.distance_from_start * DISTANCE_FACTOR) - (split2.distance_from_start * DISTANCE_FACTOR))
    end

    it 'raises an ArgumentError if the provided segment is not contained within #times_from_start' do
      ordered_splits = [split1, split2, split3, split4, split6]
      segment = Segment.new(split4.sub_splits.last, split5.sub_splits.first, split4, split5)
      sub_splits = ordered_splits.map { |split| split.sub_splits }.flatten
      times_calculator = TerrainTimesCalculator.new(sub_splits: sub_splits, ordered_splits: ordered_splits)
      expect { times_calculator.segment_time(segment) }.to raise_error(/is not valid/)
    end
  end
end