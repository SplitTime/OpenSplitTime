require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe SegmentsBuilder do
  let(:split1) { FactoryGirl.build_stubbed(:start_split, id: 101, course_id: 10, distance_from_start: 0) }
  let(:split2) { FactoryGirl.build_stubbed(:split, id: 102, course_id: 10, distance_from_start: 10000) }
  let(:split3) { FactoryGirl.build_stubbed(:split, id: 103, course_id: 10, distance_from_start: 20000) }
  let(:split4) { FactoryGirl.build_stubbed(:split, id: 104, course_id: 10, distance_from_start: 30000) }
  let(:split5) { FactoryGirl.build_stubbed(:split, id: 105, course_id: 10, distance_from_start: 40000) }
  let(:split6) { FactoryGirl.build_stubbed(:finish_split, id: 106, course_id: 10, distance_from_start: 50000) }
  let(:ordered_splits) { [split1, split2, split3, split4, split5, split6] }
  let(:sub_splits) { ordered_splits.map(&:sub_splits).flatten }

  describe '#initialize' do
    it 'initializes with a set of ordered_splits in an args hash' do
      expect { SegmentsBuilder.new(ordered_splits: ordered_splits) }.not_to raise_error
    end

    it 'initializes with a set of ordered_splits and a set of sub_splits in an args hash' do
      expect { SegmentsBuilder.new(ordered_splits: ordered_splits, sub_splits: sub_splits) }.not_to raise_error
    end

    it 'raises an error if initialized without an ordered_splits or sub_splits argument' do
      expect { SegmentsBuilder.new(random_param: 123) }.to raise_error(/must include one of/)
    end

    it 'raises an error if provided with ordered_splits and sub_splits arguments that do not reconcile' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      sub_splits = [{300 => 1}, {400 => 1}, {500 => 1}]
      expect { SegmentsBuilder.new(ordered_splits: ordered_splits, sub_splits: sub_splits) }
          .to raise_error(/do not reconcile/)
    end

    it 'raises an error if any sub_split is not included within the set of ordered_split sub_splits' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      sub_splits = ordered_splits.map(&:sub_splits).flatten + [{500 => 1}]
      expect { SegmentsBuilder.new(ordered_splits: ordered_splits, sub_splits: sub_splits) }
          .to raise_error(/do not reconcile/)
    end

    it 'raises an error if any split is not included within the set of sub_splits' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      sub_group_splits = [split1, split2, split3, split4, split5]
      sub_splits = sub_group_splits.map(&:sub_splits).flatten + [{500 => 1}]
      expect { SegmentsBuilder.new(ordered_splits: ordered_splits, sub_splits: sub_splits) }
          .to raise_error(/do not reconcile/)
    end
  end

  describe '#segments' do
    it 'returns an empty array if no sub_splits or ordered_splits are provided' do
      builder = SegmentsBuilder.new(sub_splits: [], ordered_splits: [])
      expect(builder.segments).to eq([])
    end

    it 'returns an array containing one fewer element than the sub_splits provided' do
      builder = SegmentsBuilder.new(ordered_splits: ordered_splits, sub_splits: sub_splits)
      expect(sub_splits.size).to eq(10)
      expect(builder.segments.size).to eq(9)
    end

    it 'returns segments having begin sub_splits equal to all provided sub_splits but the last' do
      builder = SegmentsBuilder.new(ordered_splits: ordered_splits, sub_splits: sub_splits)
      expect(builder.segments.map(&:begin_sub_split)).to eq(sub_splits[0..-2])
    end

    it 'returns segments having end sub_splits equal to all provided sub_splits but the first' do
      builder = SegmentsBuilder.new(ordered_splits: ordered_splits, sub_splits: sub_splits)
      expect(builder.segments.map(&:end_sub_split)).to eq(sub_splits[1..-1])
    end

    it 'returns segments having begin sub_splits equal to all determined sub_splits but the last' do
      builder = SegmentsBuilder.new(ordered_splits: ordered_splits)
      expect(builder.segments.map(&:begin_sub_split)).to eq(sub_splits[0..-2])
    end

    it 'returns segments having end sub_splits equal to all determined sub_splits but the first' do
      builder = SegmentsBuilder.new(ordered_splits: ordered_splits)
      expect(builder.segments.map(&:end_sub_split)).to eq(sub_splits[1..-1])
    end
  end
end