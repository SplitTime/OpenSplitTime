require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe StatTimesCalculator do
  describe '#initialize' do
    before do
      FactoryGirl.reload
    end

    let(:split_times_101) { FactoryGirl.build_stubbed_list(:split_times_in_out, 20, effort_id: 101).first(10) }
    let(:split_ids) { split_times_101.map(&:split_id).uniq }
    let(:split1) { FactoryGirl.build_stubbed(:start_split, id: split_ids[0], course_id: 10, distance_from_start: 0) }
    let(:split2) { FactoryGirl.build_stubbed(:split, id: split_ids[1], course_id: 10, distance_from_start: 10000) }
    let(:split3) { FactoryGirl.build_stubbed(:split, id: split_ids[2], course_id: 10, distance_from_start: 20000) }
    let(:split4) { FactoryGirl.build_stubbed(:split, id: split_ids[3], course_id: 10, distance_from_start: 30000) }
    let(:split5) { FactoryGirl.build_stubbed(:split, id: split_ids[4], course_id: 10, distance_from_start: 40000) }
    let(:split6) { FactoryGirl.build_stubbed(:finish_split, id: split_ids[5], course_id: 10, distance_from_start: 50000) }
    let(:effort1) { FactoryGirl.build_stubbed(:effort) }
    let(:effort2) { FactoryGirl.build_stubbed(:effort) }

    it 'initializes with ordered_splits and a SegmentTimesContainer object in an args hash' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      split_times = split_times_101
      times_container = SegmentTimesContainer.new(split_times: split_times)
      expect { StatTimesCalculator.new(ordered_splits: ordered_splits,
                                       segment_times_container: times_container) }.not_to raise_error
    end

    it 'initializes with ordered_splits and efforts in an args hash' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      efforts = [effort1, effort2]
      expect { StatTimesCalculator.new(ordered_splits: ordered_splits,
                                       efforts: efforts) }.not_to raise_error
    end

    it 'raises an error if initialized without an ordered_splits argument' do
      expect { StatTimesCalculator.new(random_param: 123) }.to raise_error(/must include ordered_splits/)
    end

    it 'raises an error if initialized with neither a segment_times_container nor an efforts argument' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      expect { StatTimesCalculator.new(ordered_splits: ordered_splits) }.to raise_error(/must include one of segment_times_container or efforts/)
    end
  end

  describe '#times_from_start' do
    before do
      FactoryGirl.reload
    end

    let(:split_times_101) { FactoryGirl.build_stubbed_list(:split_times_in_out, 20, effort_id: 101).first(10) }
    let(:split_times_102) { FactoryGirl.build_stubbed_list(:split_times_in_out_fast, 20, effort_id: 102).first(10) }
    let(:split_times_103) { FactoryGirl.build_stubbed_list(:split_times_in_out_slow, 20, effort_id: 103).first(10) }
    let(:split_times_104) { FactoryGirl.build_stubbed_list(:split_times_in_out, 20, effort_id: 104).first(10) }
    let(:split_times_105) { FactoryGirl.build_stubbed_list(:split_times_in_out_fast, 20, effort_id: 105).first(10) }
    let(:split_times_106) { FactoryGirl.build_stubbed_list(:split_times_in_out_slow, 20, effort_id: 106).first(10) }
    let(:split_times_107) { FactoryGirl.build_stubbed_list(:split_times_in_out, 20, effort_id: 107).first(10) }
    let(:split_times_108) { FactoryGirl.build_stubbed_list(:split_times_in_out_fast, 20, effort_id: 108).first(10) }
    let(:split_times_109) { FactoryGirl.build_stubbed_list(:split_times_in_out_slow, 20, effort_id: 109).first(10) }
    let(:split_times_110) { FactoryGirl.build_stubbed_list(:split_times_in_out, 20, effort_id: 110).first(10) }
    let(:split_times_111) { FactoryGirl.build_stubbed_list(:split_times_in_out_fast, 20, effort_id: 111).first(10) }
    let(:split_times_112) { FactoryGirl.build_stubbed_list(:split_times_in_out_slow, 20, effort_id: 112).first(5) }
    let(:split_ids) { split_times_101.map(&:split_id).uniq }
    let(:split1) { FactoryGirl.build_stubbed(:start_split, id: split_ids[0], course_id: 10, distance_from_start: 0) }
    let(:split2) { FactoryGirl.build_stubbed(:split, id: split_ids[1], course_id: 10, distance_from_start: 10000) }
    let(:split3) { FactoryGirl.build_stubbed(:split, id: split_ids[2], course_id: 10, distance_from_start: 20000) }
    let(:split4) { FactoryGirl.build_stubbed(:split, id: split_ids[3], course_id: 10, distance_from_start: 30000) }
    let(:split5) { FactoryGirl.build_stubbed(:split, id: split_ids[4], course_id: 10, distance_from_start: 40000) }
    let(:split6) { FactoryGirl.build_stubbed(:finish_split, id: split_ids[5], course_id: 10, distance_from_start: 50000) }
    let(:ordered_splits) { [split1, split2, split3, split4, split5, split6] }

    it 'returns a hash containing the same number of elements as the sub_splits of the ordered_splits provided' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      split_times = [split_times_101, split_times_102, split_times_103, split_times_104,
                     split_times_105, split_times_106, split_times_107, split_times_108,
                     split_times_109, split_times_110, split_times_111, split_times_112].flatten
      times_container = SegmentTimesContainer.new(split_times: split_times)
      times_calculator = StatTimesCalculator.new(ordered_splits: ordered_splits,
                                                 segment_times_container: times_container)
      expect(times_calculator.times_from_start.count).to eq(10)
    end

    it 'returns a hash whose keys are the same as those of the sub_splits provided' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      sub_splits = ordered_splits.map(&:sub_splits).flatten
      split_times = [split_times_101, split_times_102, split_times_103, split_times_104,
                     split_times_105, split_times_106, split_times_107, split_times_108,
                     split_times_109, split_times_110, split_times_111, split_times_112].flatten
      times_container = SegmentTimesContainer.new(split_times: split_times)
      times_calculator = StatTimesCalculator.new(ordered_splits: ordered_splits,
                                                 segment_times_container: times_container)
      expect(times_calculator.times_from_start.keys).to eq(sub_splits)
    end

    it 'returns a value of zero for the start sub_split' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      sub_splits = ordered_splits.map(&:sub_splits).flatten
      start_sub_split = sub_splits.first
      split_times = [split_times_101, split_times_102, split_times_103, split_times_104,
                     split_times_105, split_times_106, split_times_107, split_times_108,
                     split_times_109, split_times_110, split_times_111, split_times_112].flatten
      times_container = SegmentTimesContainer.new(split_times: split_times)
      times_calculator = StatTimesCalculator.new(ordered_splits: ordered_splits,
                                                 segment_times_container: times_container)
      expect(times_calculator.times_from_start[start_sub_split]).to eq(0)
    end

    it 'returns elapsed time in seconds based on statistical mean for all sub_splits' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      sub_splits = ordered_splits.map(&:sub_splits).flatten
      split_times = [split_times_101, split_times_102, split_times_103, split_times_104,
                     split_times_105, split_times_106, split_times_107, split_times_108,
                     split_times_109, split_times_110, split_times_111, split_times_112].flatten
      times_container = SegmentTimesContainer.new(split_times: split_times)
      times_calculator = StatTimesCalculator.new(ordered_splits: ordered_splits,
                                                 segment_times_container: times_container)
      expect(times_calculator.times_from_start[sub_splits[1]]).to be_within(100).of(1000)
      expect(times_calculator.times_from_start[sub_splits[2]]).to be_within(100).of(1100)
      expect(times_calculator.times_from_start[sub_splits[3]]).to be_within(100).of(2100)
      expect(times_calculator.times_from_start[sub_splits[4]]).to be_within(100).of(2200)
      expect(times_calculator.times_from_start[sub_splits[5]]).to be_within(100).of(3100)
      expect(times_calculator.times_from_start[sub_splits[6]]).to be_within(100).of(3200)
      expect(times_calculator.times_from_start[sub_splits[7]]).to be_within(100).of(4100)
      expect(times_calculator.times_from_start[sub_splits[8]]).to be_within(100).of(4200)
      expect(times_calculator.times_from_start[sub_splits[9]]).to be_within(100).of(5100)
    end
  end

  describe '#segment_time' do
    before do
      FactoryGirl.reload
    end

    let(:split_times_101) { FactoryGirl.build_stubbed_list(:split_times_in_out, 20, effort_id: 101).first(10) }
    let(:split_times_102) { FactoryGirl.build_stubbed_list(:split_times_in_out_fast, 20, effort_id: 102).first(10) }
    let(:split_times_103) { FactoryGirl.build_stubbed_list(:split_times_in_out_slow, 20, effort_id: 103).first(10) }
    let(:split_times_104) { FactoryGirl.build_stubbed_list(:split_times_in_out, 20, effort_id: 104).first(10) }
    let(:split_times_105) { FactoryGirl.build_stubbed_list(:split_times_in_out_fast, 20, effort_id: 105).first(10) }
    let(:split_times_106) { FactoryGirl.build_stubbed_list(:split_times_in_out_slow, 20, effort_id: 106).first(6) }
    let(:split_times_107) { FactoryGirl.build_stubbed_list(:split_times_in_out, 20, effort_id: 107).first(10) }
    let(:split_times_108) { FactoryGirl.build_stubbed_list(:split_times_in_out_fast, 20, effort_id: 108).first(10) }
    let(:split_times_109) { FactoryGirl.build_stubbed_list(:split_times_in_out_slow, 20, effort_id: 109).first(4) }
    let(:split_times_110) { FactoryGirl.build_stubbed_list(:split_times_in_out, 20, effort_id: 110).first(10) }
    let(:split_times_111) { FactoryGirl.build_stubbed_list(:split_times_in_out_fast, 20, effort_id: 111).first(10) }
    let(:split_times_112) { FactoryGirl.build_stubbed_list(:split_times_in_out_slow, 20, effort_id: 112).first(2) }
    let(:split_ids) { split_times_101.map(&:split_id).uniq }
    let(:split1) { FactoryGirl.build_stubbed(:start_split, id: split_ids[0], course_id: 10, distance_from_start: 0) }
    let(:split2) { FactoryGirl.build_stubbed(:split, id: split_ids[1], course_id: 10, distance_from_start: 10000) }
    let(:split3) { FactoryGirl.build_stubbed(:split, id: split_ids[2], course_id: 10, distance_from_start: 20000) }
    let(:split4) { FactoryGirl.build_stubbed(:split, id: split_ids[3], course_id: 10, distance_from_start: 30000) }
    let(:split5) { FactoryGirl.build_stubbed(:split, id: split_ids[4], course_id: 10, distance_from_start: 40000) }
    let(:split6) { FactoryGirl.build_stubbed(:finish_split, id: split_ids[5], course_id: 10, distance_from_start: 50000) }
    let(:ordered_splits) { [split1, split2, split3, split4, split5, split6] }

    it 'returns average elapsed time in seconds between begin and end of the provided segment between aid stations' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      split_times = [split_times_101, split_times_102, split_times_103, split_times_104,
                     split_times_105, split_times_106, split_times_107, split_times_108,
                     split_times_109, split_times_110, split_times_111, split_times_112].flatten
      times_container = SegmentTimesContainer.new(split_times: split_times)
      times_calculator = StatTimesCalculator.new(ordered_splits: ordered_splits,
                                                 segment_times_container: times_container)
      segment1 = Segment.new(split2.sub_splits.last, split3.sub_splits.first, split2, split3)
      segment2 = Segment.new(split3.sub_splits.last, split4.sub_splits.first, split3, split4)
      segment3 = Segment.new(split4.sub_splits.last, split5.sub_splits.first, split4, split5)
      expect(times_calculator.segment_time(segment1)).to be_within(10).of(950)
      expect(times_calculator.segment_time(segment2)).to be_within(10).of(900)
      expect(times_calculator.segment_time(segment3)).to be_within(10).of(850)
    end

    it 'returns average elapsed time in seconds between begin and end of the provided segment within an aid station' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      split_times = [split_times_101, split_times_102, split_times_103, split_times_104,
                     split_times_105, split_times_106, split_times_107, split_times_108,
                     split_times_109, split_times_110, split_times_111, split_times_112].flatten
      times_container = SegmentTimesContainer.new(split_times: split_times)
      times_calculator = StatTimesCalculator.new(ordered_splits: ordered_splits,
                                                 segment_times_container: times_container)
      segment1 = Segment.new(split2.sub_splits.first, split2.sub_splits.last, split2, split2)
      segment2 = Segment.new(split3.sub_splits.first, split3.sub_splits.last, split3, split3)
      segment3 = Segment.new(split4.sub_splits.first, split4.sub_splits.last, split4, split4)
      expect(times_calculator.segment_time(segment1)).to be_within(10).of(80)
      expect(times_calculator.segment_time(segment2)).to be_within(10).of(80)
      expect(times_calculator.segment_time(segment3)).to be_within(10).of(80)
    end

    it 'raises an ArgumentError if the provided segment is not contained within segment_times_container' do
      split_a = Split.new(id: 99998, base_name: 'Test Course Start', course_id: 99, distance_from_start: 0)
      split_b = Split.new(id: 99999, base_name: 'Test Course Aid 1', course_id: 99, distance_from_start: 10000)
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      split_times = [split_times_101, split_times_102, split_times_103, split_times_104,
                     split_times_105, split_times_106, split_times_107, split_times_108,
                     split_times_109, split_times_110, split_times_111, split_times_112].flatten
      times_container = SegmentTimesContainer.new(split_times: split_times)
      times_calculator = StatTimesCalculator.new(ordered_splits: ordered_splits,
                                                 segment_times_container: times_container)
      segment = Segment.new(split_a.sub_splits.last, split_b.sub_splits.first, split_a, split_b)
      expect { times_calculator.segment_time(segment) }.to raise_error(/is not valid/)
    end
  end
end