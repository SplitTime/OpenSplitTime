require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe SegmentTimesContainer do
  describe '#initialize' do
    it 'initializes with no arguments' do
      expect { SegmentTimesContainer.new }.not_to raise_error
    end

    it 'initializes with an args hash that contains only efforts' do
      efforts = FactoryGirl.build_stubbed_list(:effort, 4)
      expect { SegmentTimesContainer.new(efforts: efforts) }.not_to raise_error
    end

    it 'raises an ArgumentError if initialized with an args hash that contains an unknown parameter' do
      expect { SegmentTimesContainer.new(random_param: 123) }.to raise_error(/may not include random_param/)
    end

    it 'raises an ArgumentError if initialized with calc_model: :focused but without effort_ids' do
      expect { SegmentTimesContainer.new(calc_model: :focused) }.to raise_error(/cannot be initialized/)
    end

    it 'raises an ArgumentError if initialized with an unrecognized calc_model' do
      expect { SegmentTimesContainer.new(calc_model: :random) }.to raise_error(/calc_model random is not recognized/)
    end
  end

  describe '#[]' do
    let(:split1) { FactoryGirl.build_stubbed(:start_split, course_id: 10) }
    let(:split2) { FactoryGirl.build_stubbed(:split, course_id: 10) }

    it 'creates a unique SegmentTimeCalculator for each provided segment' do
      container = SegmentTimesContainer.new(calc_model: :terrain)
      segment1 = Segment.new(split1.sub_splits.last, split2.sub_splits.first, split1, split2)
      segment2 = Segment.new(split2.sub_splits.first, split2.sub_splits.last, split2, split2)
      expect(container[segment1]).to be_a(SegmentTimeCalculator)
      expect(container[segment2]).to be_a(SegmentTimeCalculator)
      expect(container[segment1]).not_to eq(container[segment2])
    end

    it 'returns the same SegmentTimeCalculator for each provided segment once created' do
      container = SegmentTimesContainer.new(calc_model: :terrain)
      segment1 = Segment.new(split1.sub_splits.last, split2.sub_splits.first, split1, split2)
      calculator1 = container[segment1]
      calculator2 = container[segment1]
      expect(calculator1).to eq(calculator2)
    end
  end

  describe '#segment_time' do
    let(:split1) { FactoryGirl.build_stubbed(:start_split, course_id: 10) }
    let(:split2) { FactoryGirl.build_stubbed(:split, course_id: 10, distance_from_start: 10000) }
    let(:split3) { FactoryGirl.build_stubbed(:split, course_id: 10, distance_from_start: 25000) }

    it 'returns a segment time in seconds using the provided calc_model' do
      container = SegmentTimesContainer.new(calc_model: :terrain)
      segment1 = Segment.new(split1.sub_splits.last, split2.sub_splits.first, split1, split2)
      segment2 = Segment.new(split2.sub_splits.first, split2.sub_splits.last, split2, split2)
      segment3 = Segment.new(split2.sub_splits.last, split3.sub_splits.first, split2, split3)
      expect(container.segment_time(segment1)).to eq(10000 * Segment::DISTANCE_FACTOR)
      expect(container.segment_time(segment2)).to eq(Segment::TYPICAL_TIME_IN_AID)
      expect(container.segment_time(segment3)).to eq(15000 * Segment::DISTANCE_FACTOR)
    end
  end

  describe '#limits' do
    let(:split1) { FactoryGirl.build_stubbed(:start_split, course_id: 10) }
    let(:split2) { FactoryGirl.build_stubbed(:split, course_id: 10, distance_from_start: 10000) }
    let(:split3) { FactoryGirl.build_stubbed(:split, course_id: 10, distance_from_start: 25000) }

    it 'returns a limits hash for segments both between and within splits, using the provided calc_model' do
      container = SegmentTimesContainer.new(calc_model: :terrain)
      segment1 = Segment.new(split1.sub_splits.last, split2.sub_splits.first, split1, split2)
      segment2 = Segment.new(split2.sub_splits.first, split2.sub_splits.last, split2, split2)
      limits1 = container.limits(segment1)
      limits2 = container.limits(segment2)
      expect(limits1[:low_bad]).not_to be_nil
      expect(limits1[:low_questionable]).not_to be_nil
      expect(limits1[:high_questionable]).not_to be_nil
      expect(limits1[:high_bad]).not_to be_nil
      expect(limits2[:low_bad]).not_to be_nil
      expect(limits2[:low_questionable]).not_to be_nil
      expect(limits2[:high_questionable]).not_to be_nil
      expect(limits2[:high_bad]).not_to be_nil
    end
  end

  describe '#data_status' do
    let(:split1) { FactoryGirl.build_stubbed(:start_split, course_id: 10) }
    let(:split2) { FactoryGirl.build_stubbed(:split, course_id: 10, distance_from_start: 10000) }
    let(:split3) { FactoryGirl.build_stubbed(:split, course_id: 10, distance_from_start: 25000) }

    it 'returns a data status based on calculated limits' do
      container = SegmentTimesContainer.new(calc_model: :terrain)
      segment1 = Segment.new(split1.sub_splits.last, split2.sub_splits.first, split1, split2)
      segment2 = Segment.new(split2.sub_splits.first, split2.sub_splits.last, split2, split2)
      segment3 = Segment.new(split2.sub_splits.last, split3.sub_splits.first, split2, split3)
      expect(container.data_status(segment1, 10000 * Segment::DISTANCE_FACTOR)).to eq('good')
      expect(container.data_status(segment2, 0)).to eq('good')
      expect(container.data_status(segment3, 100_000)).to eq('bad')
    end
  end
end