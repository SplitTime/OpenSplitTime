require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe SegmentTimeCalculator do
  DISTANCE_FACTOR ||= SegmentTimeCalculator::DISTANCE_FACTOR

  describe '#initialize' do
    let(:split1) { FactoryGirl.build_stubbed(:start_split, course_id: 10) }
    let(:split2) { FactoryGirl.build_stubbed(:split, course_id: 10) }

    it 'initializes with an args hash that contains only a calc_model and a segment' do
      segment = Segment.new(begin_sub_split: split1.sub_splits.last, end_sub_split: split2.sub_splits.first, begin_split: split1, end_split: split2)
      expect { SegmentTimeCalculator.new(segment: segment, calc_model: :terrain) }.not_to raise_error
    end

    it 'raises an ArgumentError if initialized without a calc_model' do
      segment = Segment.new(begin_sub_split: split1.sub_splits.last, end_sub_split: split2.sub_splits.first, begin_split: split1, end_split: split2)
      expect { SegmentTimeCalculator.new(segment: segment) }.to raise_error(/must include calc_model/)
    end

    it 'raises an ArgumentError if initialized without a segment' do
      expect { SegmentTimeCalculator.new(calc_model: :terrain) }.to raise_error(/must include segment/)
    end

    it 'raises an ArgumentError if initialized with calc_model: :focused but without effort_ids' do
      segment = Segment.new(begin_sub_split: split1.sub_splits.last, end_sub_split: split2.sub_splits.first, begin_split: split1, end_split: split2)
      expect { SegmentTimeCalculator.new(segment: segment, calc_model: :focused) }.to raise_error(/cannot be initialized/)
    end

    it 'raises an ArgumentError if initialized with an unrecognized calc_model' do
      segment = Segment.new(begin_sub_split: split1.sub_splits.last, end_sub_split: split2.sub_splits.first, begin_split: split1, end_split: split2)
      expect { SegmentTimeCalculator.new(segment: segment, calc_model: :random) }.to raise_error(/calc_model random is not recognized/)
    end
  end

  describe '#typical_time' do
    let(:split1) { FactoryGirl.build_stubbed(:start_split, course_id: 10) }
    let(:split2) { FactoryGirl.build_stubbed(:split, course_id: 10, distance_from_start: 10000) }

    it 'calculates a segment time in seconds using the specified calc_model' do
      segment = Segment.new(begin_sub_split: split1.sub_splits.last, end_sub_split: split2.sub_splits.first, begin_split: split1, end_split: split2)
      calculator = SegmentTimeCalculator.new(segment: segment, calc_model: :terrain)
      expect(calculator.typical_time).to eq(10000 * DISTANCE_FACTOR)
    end

    it 'returns zero for a segment that begins and ends with a start split' do
      segment = Segment.new(begin_sub_split: split1.sub_splits.first, end_sub_split: split1.sub_splits.first, begin_split: split1, end_split: split1)
      calculator = SegmentTimeCalculator.new(segment: segment, calc_model: :terrain)
      expect(calculator.typical_time).to eq(0)
    end

    it 'returns typical time in aid for a segment that begins and ends within an intermediate split' do
      segment = Segment.new(begin_sub_split: split2.sub_splits.first, end_sub_split: split2.sub_splits.last, begin_split: split2, end_split: split2)
      calculator = SegmentTimeCalculator.new(segment: segment, calc_model: :terrain)
      expect(calculator.typical_time).to eq(0)
    end
  end
end