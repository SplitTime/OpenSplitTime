require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe SegmentsBuilder do
  let(:split1) { FactoryGirl.build_stubbed(:start_split, id: 101, course_id: 10, distance_from_start: 0) }
  let(:split2) { FactoryGirl.build_stubbed(:split, id: 102, course_id: 10, distance_from_start: 10000) }
  let(:split3) { FactoryGirl.build_stubbed(:split, id: 103, course_id: 10, distance_from_start: 20000) }
  let(:split4) { FactoryGirl.build_stubbed(:split, id: 104, course_id: 10, distance_from_start: 30000) }
  let(:split5) { FactoryGirl.build_stubbed(:split, id: 105, course_id: 10, distance_from_start: 40000) }
  let(:split6) { FactoryGirl.build_stubbed(:finish_split, id: 106, course_id: 10, distance_from_start: 50000) }

  describe '#initialize' do
    it 'initializes with a set of ordered_splits in an args hash' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      expect { SegmentsBuilder.new(ordered_splits: ordered_splits) }.not_to raise_error
    end

    it 'initializes with a set of ordered_splits and an optional working_sub_split in an args hash' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      sub_split = split1.sub_splits.first
      expect { SegmentsBuilder.new(ordered_splits: ordered_splits, working_sub_split: sub_split) }.not_to raise_error
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

    it 'raises an error if working_sub_split and sub_splits do not reconcile' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      sub_splits = ordered_splits.map(&:sub_splits).flatten
      working_sub_split = {999 => 99}
      expect { SegmentsBuilder.new(ordered_splits: ordered_splits, working_sub_split: working_sub_split) }
          .to raise_error(/working sub_split is not contained within/)
    end
  end

  describe '#segments' do
    context 'when no working_sub_split is provided' do
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

    context 'when a working_sub_split is provided that is the start sub_split' do
      it 'returns an array containing the same number of elements as the sub_splits provided' do
        ordered_splits = [split1, split2, split3, split4, split5, split6]
        working_sub_split = split1.sub_split_in
        builder = SegmentsBuilder.new(ordered_splits: ordered_splits, working_sub_split: working_sub_split)
        expect(builder.segments.count).to eq(10)
      end

      it 'returns segments having all begin splits based on the working_sub_split' do
        ordered_splits = [split1, split2, split3, split4, split5, split6]
        working_sub_split = split1.sub_split_in
        builder = SegmentsBuilder.new(ordered_splits: ordered_splits, working_sub_split: working_sub_split)
        expect(builder.segments.map(&:begin_split).uniq).to eq([split1])
      end

      it 'returns segments having end splits relating to the series of provided sub_splits' do
        ordered_splits = [split1, split2, split3, split4, split5, split6]
        working_sub_split = split1.sub_split_in
        builder = SegmentsBuilder.new(ordered_splits: ordered_splits, working_sub_split: working_sub_split)
        expect(builder.segments.map(&:end_split)).to eq([split1, split2, split2, split3, split3,
                                                         split4, split4, split5, split5, split6])
      end
    end

    context 'when a working_sub_split is provided that is not the start sub_split' do
      it 'returns an array containing the same number of elements as the sub_splits provided' do
        ordered_splits = [split1, split2, split3, split4, split5, split6]
        working_sub_split = split3.sub_split_in
        builder = SegmentsBuilder.new(ordered_splits: ordered_splits, working_sub_split: working_sub_split)
        expect(builder.segments.count).to eq(10)
      end

      it 'returns segments having all begin splits based on the working_sub_split' do
        ordered_splits = [split1, split2, split3, split4, split5, split6]
        working_sub_split = split3.sub_split_in
        builder = SegmentsBuilder.new(ordered_splits: ordered_splits, working_sub_split: working_sub_split)
        expect(builder.segments.map(&:begin_split).uniq).to eq([split3])
      end

      it 'returns segments having end splits relating to the series of provided sub_splits' do
        ordered_splits = [split1, split2, split3, split4, split5, split6]
        working_sub_split = split1.sub_split_in
        builder = SegmentsBuilder.new(ordered_splits: ordered_splits, working_sub_split: working_sub_split)
        expect(builder.segments.map(&:end_split)).to eq([split1, split2, split2, split3, split3,
                                                         split4, split4, split5, split5, split6])
      end
    end
  end
end