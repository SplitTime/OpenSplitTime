require 'rails_helper'

RSpec.describe SimilarEffortFinder, type: :model do
  describe '#initialize' do
    it 'initializes when provided with a sub_split and time_from_start' do
      sub_split = {110 => 1}
      time_from_start = 10000
      expect { SimilarEffortFinder.new(sub_split: sub_split, time_from_start: time_from_start) }.not_to raise_error
    end

    it 'initializes when provided with a split_time' do
      split_time = FactoryGirl.build_stubbed(:split_times_in_only)
      expect { SimilarEffortFinder.new(split_time: split_time) }.not_to raise_error
    end
  end

  describe '#effort_ids' do
    it 'returns an empty array when no efforts meet the provided criteria' do
      effort_times = {}
      split_time = FactoryGirl.build_stubbed(:split_times_in_only)
      finder = SimilarEffortFinder.new(split_time: split_time)
      allow(finder).to receive(:effort_times).and_return(effort_times)
      expect(finder.effort_ids).to eq([])
    end

    it 'returns an array of effort ids for the elements of #effort_times that meet the provided criteria' do
      effort_times = {101 => 9000,
                      102 => 10000,
                      103 => 11000,
                      104 => 20000,
                      105 => 21000,
                      106 => 22000}
      sub_split = {110 => 1}
      time_from_start = 10000
      finder = SimilarEffortFinder.new(sub_split: sub_split, time_from_start: time_from_start, min: 3)
      allow(finder).to receive(:effort_times).and_return(effort_times)
      expect(finder.effort_ids).to eq([101, 102, 103])
    end

    it 'limits the set of ids to those elements of #effort_times that most closely meet the provided criteria' do
      effort_times = {90=>6000,
                      91=>6500,
                      92=>7000,
                      101 => 9000,
                      102 => 10000,
                      103 => 11000,
                      104 => 13000,
                      105 => 14000,
                      106 => 15000}
      sub_split = {110 => 1}
      time_from_start = 10000
      finder = SimilarEffortFinder.new(sub_split: sub_split, time_from_start: time_from_start, min: 3)
      allow(finder).to receive(:effort_times).and_return(effort_times)
      expect(finder.effort_ids).to eq([101, 102, 103])
    end

    it 'expands to include additional elements of #effort_times as min: argument increases' do
      effort_times = {90=>6000,
                      91=>6500,
                      92=>7000,
                      101 => 9000,
                      102 => 10000,
                      103 => 11000,
                      104 => 13000,
                      105 => 14000,
                      106 => 15000}
      sub_split = {110 => 1}
      time_from_start = 10000
      finder = SimilarEffortFinder.new(sub_split: sub_split, time_from_start: time_from_start, min: 4)
      allow(finder).to receive(:effort_times).and_return(effort_times)
      expect(finder.effort_ids).to eq([92, 101, 102, 103, 104])
    end
  end
end