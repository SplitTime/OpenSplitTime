require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe SegmentTimesPlanner do
  let(:split_times_101) { FactoryGirl.build_stubbed_list(:split_times_in_out, 20, effort_id: 101).first(10) }
  let(:split_ids) { split_times_101.map(&:split_id).uniq }
  let(:split1) { FactoryGirl.build_stubbed(:start_split, id: split_ids[0], course_id: 10, distance_from_start: 0) }
  let(:split2) { FactoryGirl.build_stubbed(:split, id: split_ids[1], course_id: 10, distance_from_start: 1000) }
  let(:split3) { FactoryGirl.build_stubbed(:split, id: split_ids[2], course_id: 10, distance_from_start: 2000) }
  let(:split4) { FactoryGirl.build_stubbed(:split, id: split_ids[3], course_id: 10, distance_from_start: 3000) }
  let(:split5) { FactoryGirl.build_stubbed(:split, id: split_ids[4], course_id: 10, distance_from_start: 4000) }
  let(:split6) { FactoryGirl.build_stubbed(:finish_split, id: split_ids[5], course_id: 10, distance_from_start: 5000) }
  let(:ordered_splits) { [split1, split2, split3, split4, split5, split6] }
  let(:segments) { SegmentsBuilder.segments_with_zero_start(ordered_splits: ordered_splits) }
  let(:sub_splits) { ordered_splits.map(&:sub_splits).flatten }

  describe '#initialize' do
    it 'initializes with expected_time and ordered_splits in an args hash' do
      expected_time = 1000
      expect { SegmentTimesPlanner.new(expected_time: expected_time, ordered_splits: ordered_splits) }.not_to raise_error
    end

    it 'raises an ArgumentError if no ordered_splits are given' do
      expected_time = 1000
      expect { SegmentTimesPlanner.new(expected_time: expected_time) }.to raise_error(/must include ordered_splits/)
    end

    it 'raises an ArgumentError if no expected_time is given' do
      expect { SegmentTimesPlanner.new(ordered_splits: ordered_splits) }.to raise_error(/must include expected_time/)
    end
  end

  describe '#times_from_start' do
    it 'returns a hash containing keys corresponding to the segments generated from ordered_splits' do
      expected_time = 4000
      planner = SegmentTimesPlanner.new(expected_time: expected_time,
                                        ordered_splits: ordered_splits,
                                        calc_model: :terrain)
      expect(planner.times_from_start.size).to eq(sub_splits.size)
      expect(planner.times_from_start.keys).to eq(sub_splits)
    end

    it 'returns values corresponding to the expected times from start when expected_time equals total segment times' do
      expected_time = 3000
      planner = SegmentTimesPlanner.new(expected_time: expected_time,
                                        ordered_splits: ordered_splits,
                                        calc_model: :terrain)
      expect(planner.times_from_start.values).to eq([0, 600, 600, 1200, 1200, 1800, 1800, 2400, 2400, 3000])
    end

    it 'returns values adjusted for pace when expected_time does not equal total segment times' do
      expected_time = 4500
      planner = SegmentTimesPlanner.new(expected_time: expected_time,
                                        ordered_splits: ordered_splits,
                                        calc_model: :terrain)
      expect(planner.times_from_start.values).to eq([0, 900, 900, 1800, 1800, 2700, 2700, 3600, 3600, 4500])
    end

    it 'returns nil when any expected segment time is nil' do
      expected_time = 4500
      planner = SegmentTimesPlanner.new(expected_time: expected_time,
                                        ordered_splits: ordered_splits,
                                        calc_model: :terrain)
      allow(planner).to receive(:serial_times).and_return([0, nil, 1000])
      expect(planner.times_from_start).to be_nil
    end
  end

  describe '#segment_times' do
    it 'returns a hash containing keys corresponding to the sub_splits generated from ordered_splits' do
      expected_time = 4000
      planner = SegmentTimesPlanner.new(expected_time: expected_time,
                                        ordered_splits: ordered_splits,
                                        calc_model: :terrain)
      expect(planner.segment_times.size).to eq(segments.size)
      expect(planner.segment_times.keys).to eq(segments)
    end

    it 'returns values corresponding to the expected segment_times when expected_time equals total segment times' do
      expected_time = 3000
      planner = SegmentTimesPlanner.new(expected_time: expected_time,
                                        ordered_splits: ordered_splits,
                                        calc_model: :terrain)
      expect(planner.segment_times.values).to eq([0, 600, 0, 600, 0, 600, 0, 600, 0, 600])
    end

    it 'returns values adjusted for pace when expected_time does not equal total segment times' do
      expected_time = 4500
      planner = SegmentTimesPlanner.new(expected_time: expected_time,
                                        ordered_splits: ordered_splits,
                                        calc_model: :terrain)
      expect(planner.segment_times.values).to eq([0, 900, 0, 900, 0, 900, 0, 900, 0, 900])
    end

    it 'returns nil when any expected segment time is nil' do
      expected_time = 4500
      planner = SegmentTimesPlanner.new(expected_time: expected_time,
                                        ordered_splits: ordered_splits,
                                        calc_model: :terrain)
      allow(planner).to receive(:serial_times).and_return([0, nil, 1000])
      expect(planner.segment_times).to be_nil
    end
  end
end