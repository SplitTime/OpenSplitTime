require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe EffortSegmentCalcs do
  describe '#initialize' do
    before do
      FactoryGirl.reload
    end

    it 'initializes with an args hash that contains only split_times' do
      split_times = FactoryGirl.build_stubbed_list(:split_times_in_out, 8)
      calcs = EffortSegmentCalcs.new(split_times: split_times)
      expect(calcs.time_hashes.count).to eq(8)
    end

    it 'initializes with an args hash that contains split_times and efforts' do
      efforts = FactoryGirl.build_stubbed_list(:effort, 4)
      split_times = FactoryGirl.build_stubbed_list(:split_times_in_out, 8)
      calcs = EffortSegmentCalcs.new(efforts: efforts, split_times: split_times)
      expect(calcs.time_hashes.count).to eq(8)
    end

    it 'initializes with an args hash that contains split_times and effort_ids' do
      split_times = FactoryGirl.build_stubbed_list(:split_times_in_out, 8)
      effort_ids = split_times.map(&:effort_id)
      calcs = EffortSegmentCalcs.new(effort_ids: effort_ids, split_times: split_times)
      expect(calcs.time_hashes.count).to eq(8)
    end
  end

  describe '#time_hashes' do
    before do
      FactoryGirl.reload
    end

    let(:split_times_101) { FactoryGirl.build_stubbed_list(:split_times_in_out, 20, effort_id: 101) }
    let(:split_times_102) { FactoryGirl.build_stubbed_list(:split_times_in_out_fast, 20, effort_id: 102) }
    let(:split_times_103) { FactoryGirl.build_stubbed_list(:split_times_in_out_slow, 20, effort_id: 103) }

    it 'exists for each sub_split contained in split_times' do
      split_times = [split_times_101, split_times_102, split_times_103].flatten
      calcs = EffortSegmentCalcs.new(split_times: split_times)
      expect(calcs.time_hashes.count).to eq(20)
    end

    it 'exists even if some sub_splits are not contained in all efforts' do
      split_times = [split_times_101, split_times_102.first(10), split_times_103.first(10)].flatten
      calcs = EffortSegmentCalcs.new(split_times: split_times)
      expect(calcs.time_hashes.count).to eq(20)
    end

    it 'contains accurate time data for each provided split_time' do
      split_times = [split_times_101.first(5), split_times_102.first(3), split_times_103.first(2)].flatten
      sub_split0 = split_times[0].sub_split
      sub_split1 = split_times[1].sub_split
      sub_split2 = split_times[2].sub_split
      sub_split3 = split_times[3].sub_split
      sub_split4 = split_times[4].sub_split
      calcs = EffortSegmentCalcs.new(split_times: split_times)
      expect(calcs.time_hashes[sub_split0]).to eq({101 => 0, 102 => 0, 103 => 0})
      expect(calcs.time_hashes[sub_split1]).to eq({101 => 1000, 102 => 700, 103 => 1500})
      expect(calcs.time_hashes[sub_split2]).to eq({101 => 1100, 102 => 750})
      expect(calcs.time_hashes[sub_split3]).to eq({101 => 2000})
      expect(calcs.time_hashes[sub_split4]).to eq({101 => 2100})
    end
  end

  describe '#[] and #segment_calcs' do
    before do
      FactoryGirl.reload
    end

    let(:split_times_101) { FactoryGirl.build_stubbed_list(:split_times_in_out, 20, effort_id: 101) }
    let(:split_times_102) { FactoryGirl.build_stubbed_list(:split_times_in_out_fast, 20, effort_id: 102) }
    let(:split_times_103) { FactoryGirl.build_stubbed_list(:split_times_in_out_slow, 20, effort_id: 103) }
    let(:split1) { FactoryGirl.build_stubbed(:start_split, id: split_times_101.first.split_id, course_id: 10) }
    let(:split2) { FactoryGirl.build_stubbed(:split, id: split_times_101.second.split_id, course_id: 10) }
    let(:split3) { FactoryGirl.build_stubbed(:split, id: split_times_101.fourth.split_id, course_id: 10) }

    it 'stores segment calculations between splits' do
      split_times = [split_times_101, split_times_102, split_times_103].flatten
      calcs = EffortSegmentCalcs.new(split_times: split_times)
      begin_sub_split = split1.sub_splits.last
      end_sub_split =  split2.sub_splits.first
      segment = Segment.new(begin_sub_split, end_sub_split, split1, split2)
      expect(calcs[segment]).to be_a(SegmentCalculations)
      expect(calcs[segment].times).to eq({101=>1000, 102=>700, 103=>1500})
    end

    it 'stores other segment calculations between splits' do
      split_times = [split_times_101, split_times_102, split_times_103].flatten
      calcs = EffortSegmentCalcs.new(split_times: split_times)
      begin_sub_split = split2.sub_splits.last
      end_sub_split =  split3.sub_splits.first
      segment = Segment.new(begin_sub_split, end_sub_split, split2, split3)
      expect(calcs[segment]).to be_a(SegmentCalculations)
      expect(calcs[segment].times).to eq({101=>900, 102=>650, 103=>1400})
    end

    it 'stores segment calculations within a split' do
      split_times = [split_times_101, split_times_102, split_times_103].flatten
      calcs = EffortSegmentCalcs.new(split_times: split_times)
      begin_sub_split = split2.sub_splits.first
      end_sub_split =  split2.sub_splits.last
      segment = Segment.new(begin_sub_split, end_sub_split, split2, split2)
      expect(calcs[segment]).to be_a(SegmentCalculations)
      expect(calcs[segment].times).to eq({101=>100, 102=>50, 103=>100})
    end
  end
end