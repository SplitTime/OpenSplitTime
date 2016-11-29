require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe PriorSplitTimeFinder do
  let(:split_times_101) { FactoryGirl.build_stubbed_list(:split_times_in_out, 20,
                                                         effort_id: 101,
                                                         data_status: SplitTime::data_statuses[:good]).first(10) }
  let(:split_ids) { split_times_101.map(&:split_id).uniq }
  let(:split1) { FactoryGirl.build_stubbed(:start_split, id: split_ids[0], course_id: 10, distance_from_start: 0) }
  let(:split2) { FactoryGirl.build_stubbed(:split, id: split_ids[1], course_id: 10, distance_from_start: 1000) }
  let(:split3) { FactoryGirl.build_stubbed(:split, id: split_ids[2], course_id: 10, distance_from_start: 2000) }
  let(:split4) { FactoryGirl.build_stubbed(:split, id: split_ids[3], course_id: 10, distance_from_start: 3000) }
  let(:split5) { FactoryGirl.build_stubbed(:split, id: split_ids[4], course_id: 10, distance_from_start: 4000) }
  let(:split6) { FactoryGirl.build_stubbed(:finish_split, id: split_ids[5], course_id: 10, distance_from_start: 5000) }

  describe '#initialize' do

    it 'initializes with an effort, a sub_split, ordered_splits, and split_times in an args hash' do
      effort = FactoryGirl.build_stubbed(:effort, id: 101)
      sub_split = split_times_101.last.sub_split
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      split_times = split_times_101
      expect { PriorSplitTimeFinder.new(effort: effort,
                                        sub_split: sub_split,
                                        ordered_splits: ordered_splits,
                                        split_times: split_times) }.not_to raise_error
    end

    it 'raises an ArgumentError if neither effort nor ordered_splits is given' do
      sub_split = split_times_101.last.sub_split
      expect { PriorSplitTimeFinder.new(sub_split: sub_split) }.to raise_error(/must include one of effort or ordered_splits/)
    end

    it 'raises an ArgumentError if no sub_split is given' do
      effort = FactoryGirl.build_stubbed(:effort)
      expect { PriorSplitTimeFinder.new(effort: effort) }.to raise_error(/must include sub_split/)
    end
  end

  describe '#split_time' do
    before do
      FactoryGirl.reload
    end

    it 'when all split_times are valid, returns the split_time that comes immediately prior to the provided sub_split' do
      effort = FactoryGirl.build_stubbed(:effort, id: 101)
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      split_times = split_times_101
      sub_split = split_times[5].sub_split
      finder = PriorSplitTimeFinder.new(effort: effort,
                                        sub_split: sub_split,
                                        ordered_splits: ordered_splits,
                                        split_times: split_times)
      expected = split_times[4]
      expect(finder.split_time).to eq(expected)
    end

    it 'when some split_times are invalid, returns the latest valid split_time that comes prior to the provided sub_split' do
      effort = FactoryGirl.build_stubbed(:effort, id: 101)
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      split_times = split_times_101
      split_times[4].data_status = 'bad'
      split_times[3].data_status = 'questionable'
      sub_split = split_times[5].sub_split
      finder = PriorSplitTimeFinder.new(effort: effort,
                                        sub_split: sub_split,
                                        ordered_splits: ordered_splits,
                                        split_times: split_times)
      expected = split_times[2]
      expect(finder.split_time).to eq(expected)
    end

    it 'when all prior split_times are invalid, returns a mock starting split_time' do
      effort = FactoryGirl.build_stubbed(:effort, id: 101)
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      split_times = split_times_101
      split_times[4].data_status = 'bad'
      split_times[3].data_status = 'questionable'
      split_times[2].data_status = 'bad'
      split_times[1].data_status = 'questionable'
      split_times[0].data_status = 'bad'
      sub_split = split_times[5].sub_split
      finder = PriorSplitTimeFinder.new(effort: effort,
                                        sub_split: sub_split,
                                        ordered_splits: ordered_splits,
                                        split_times: split_times)
      expected = SplitTime.new(sub_split: split_times[0].sub_split, time_from_start: 0, id: nil, effort_id: nil)
      expect(finder.split_time.attributes).to eq(expected.attributes)
    end

    it 'when the starting sub_split is provided, returns a mock starting split_time' do
      effort = FactoryGirl.build_stubbed(:effort, id: 101)
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      split_times = split_times_101
      sub_split = split_times[0].sub_split
      finder = PriorSplitTimeFinder.new(effort: effort,
                                        sub_split: sub_split,
                                        ordered_splits: ordered_splits,
                                        split_times: split_times)
      expected = SplitTime.new(sub_split: sub_split, time_from_start: 0, id: nil, effort_id: nil)
      expect(finder.split_time.attributes).to eq(expected.attributes)
    end
  end
end