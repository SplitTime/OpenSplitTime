require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe SegmentsBuilder do
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
      expect { SegmentsBuilder.new(ordered_splits: ordered_splits) }.not_to raise_error
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

    it 'returns an array containing the same number of elements as the sub_splits provided' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      builder = SegmentsBuilder.new(ordered_splits: ordered_splits)
      expect(builder.segments.count).to eq(10)
    end

    it 'returns an array of Segment objects whose end_sub_splits are the same as those of the sub_splits provided' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      builder = SegmentsBuilder.new(ordered_splits: ordered_splits)
      sub_splits = ordered_splits.map { |split| split.sub_splits }.flatten
      expect(builder.segments.map(&:end_sub_split)).to eq(sub_splits)
    end

    it 'returns segments having all begin splits based on the first provided sub_split' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      builder = SegmentsBuilder.new(ordered_splits: ordered_splits)
      expect(builder.segments.map(&:begin_split).uniq).to eq([split1])
    end

    it 'returns segments having end splits relating to the series of provided sub_splits' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      builder = SegmentsBuilder.new(ordered_splits: ordered_splits)
      expect(builder.segments.map(&:end_split)).to eq([split1, split2, split2, split3, split3,
                                                       split4, split4, split5, split5, split6])
    end
  end
end