require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe SegmentTimeCalculator do
  describe '#initialize' do
    let(:split1) { FactoryGirl.build_stubbed(:start_split, course_id: 10) }
    let(:split2) { FactoryGirl.build_stubbed(:split, course_id: 10) }

    it 'initializes with an args hash that contains only a calc_model and a segment' do
      segment = Segment.new(split1.sub_splits.last, split2.sub_splits.first, split1, split2)
      expect { SegmentTimeCalculator.new(segment: segment, calc_model: :terrain) }.not_to raise_error
    end

    it 'raises an ArgumentError if initialized without a calc_model' do
      segment = Segment.new(split1.sub_splits.last, split2.sub_splits.first, split1, split2)
      expect { SegmentTimeCalculator.new(segment: segment) }.to raise_error(/must include calc_model/)
    end

    it 'raises an ArgumentError if initialized without a segment' do
      expect { SegmentTimeCalculator.new(calc_model: :terrain) }.to raise_error(/must include segment/)
    end

    it 'raises an ArgumentError if initialized with calc_model: :focused but without effort_ids' do
      segment = Segment.new(split1.sub_splits.last, split2.sub_splits.first, split1, split2)
      expect { SegmentTimeCalculator.new(segment: segment, calc_model: :focused) }.to raise_error(/cannot be initialized/)
    end

    it 'raises an ArgumentError if initialized with an unrecognized calc_model' do
      segment = Segment.new(split1.sub_splits.last, split2.sub_splits.first, split1, split2)
      expect { SegmentTimeCalculator.new(segment: segment, calc_model: :random) }.to raise_error(/calc_model random is not recognized/)
    end
  end

  describe '#calculated_time' do
    let(:split1) { FactoryGirl.build_stubbed(:start_split, course_id: 10) }
    let(:split2) { FactoryGirl.build_stubbed(:split, course_id: 10, distance_from_start: 10000) }

    it 'calculates a segment time in seconds using the specified calc_model' do
      segment = Segment.new(split1.sub_splits.last, split2.sub_splits.first, split1, split2)
      calculator = SegmentTimeCalculator.new(segment: segment, calc_model: :terrain)
      expect(calculator.calculated_time).to eq(10000 * Segment::DISTANCE_FACTOR)
    end

    it 'returns zero for a segment that begins and ends with a start split' do
      segment = Segment.new(split1.sub_splits.first, split1.sub_splits.first, split1, split1)
      calculator = SegmentTimeCalculator.new(segment: segment, calc_model: :terrain)
      expect(calculator.calculated_time).to eq(0)
    end

    it 'returns typical time in aid for a segment that begins and ends within an intermediate split' do
      segment = Segment.new(split2.sub_splits.first, split2.sub_splits.last, split2, split2)
      calculator = SegmentTimeCalculator.new(segment: segment, calc_model: :terrain)
      expect(calculator.calculated_time).to eq(Segment::TYPICAL_TIME_IN_AID)
    end
  end

  describe '#limits' do
    let(:split1) { FactoryGirl.build_stubbed(:start_split, course_id: 10) }
    let(:split2) { FactoryGirl.build_stubbed(:split, course_id: 10, distance_from_start: 10000) }

    it 'returns a limits hash for segments both between and within splits, using the provided calc_model' do
      segment1 = Segment.new(split1.sub_splits.last, split2.sub_splits.first, split1, split2)
      segment2 = Segment.new(split2.sub_splits.first, split2.sub_splits.last, split2, split2)
      calculator1 = SegmentTimeCalculator.new(segment: segment1, calc_model: :terrain)
      calculator2 = SegmentTimeCalculator.new(segment: segment2, calc_model: :terrain)
      limits1 = calculator1.limits
      limits2 = calculator2.limits
      expect(limits1[:low_bad]).not_to be_nil
      expect(limits1[:low_questionable]).not_to be_nil
      expect(limits1[:high_questionable]).not_to be_nil
      expect(limits1[:high_bad]).not_to be_nil
      expect(limits2[:low_bad]).not_to be_nil
      expect(limits2[:low_questionable]).not_to be_nil
      expect(limits2[:high_questionable]).not_to be_nil
      expect(limits2[:high_bad]).not_to be_nil
    end

    it 'returns a limits hash of all zeros for a segment that begins and ends with a start split' do
      segment1 = Segment.new(split1.sub_splits.first, split1.sub_splits.first, split1, split1)
      calculator1 = SegmentTimeCalculator.new(segment: segment1, calc_model: :terrain)
      limits1 = calculator1.limits
      expect(limits1[:low_bad]).to eq(0)
      expect(limits1[:low_questionable]).to eq(0)
      expect(limits1[:high_questionable]).to eq(0)
      expect(limits1[:high_bad]).to eq(0)
    end
  end

  describe '#data_status' do
    let(:split1) { FactoryGirl.build_stubbed(:start_split, course_id: 10) }
    let(:split2) { FactoryGirl.build_stubbed(:split, course_id: 10, distance_from_start: 10000) }
    let(:split3) { FactoryGirl.build_stubbed(:split, course_id: 10, distance_from_start: 25000) }

    it 'returns a data status based on calculated limits' do
      segment1 = Segment.new(split1.sub_splits.last, split2.sub_splits.first, split1, split2)
      segment2 = Segment.new(split2.sub_splits.first, split2.sub_splits.last, split2, split2)
      segment3 = Segment.new(split2.sub_splits.last, split3.sub_splits.first, split2, split3)
      calculator1 = SegmentTimeCalculator.new(segment: segment1, calc_model: :terrain)
      calculator2 = SegmentTimeCalculator.new(segment: segment2, calc_model: :terrain)
      calculator3 = SegmentTimeCalculator.new(segment: segment3, calc_model: :terrain)
      expect(calculator1.data_status(10000 * Segment::DISTANCE_FACTOR)).to eq('good')
      expect(calculator1.data_status(100_000)).to eq('bad')
      expect(calculator1.data_status(0)).to eq('bad')
      expect(calculator2.data_status(0)).to eq('good')
      expect(calculator2.data_status(-100)).to eq('bad')
      expect(calculator2.data_status(1.day)).to eq('questionable')
      expect(calculator2.data_status(2.days)).to eq('bad')
      expect(calculator3.data_status(15000 * Segment::DISTANCE_FACTOR)).to eq('good')
      expect(calculator3.data_status(1000)).to eq('bad')
      expect(calculator3.data_status(100_000 * Segment::DISTANCE_FACTOR)).to eq('bad')
    end
  end
end