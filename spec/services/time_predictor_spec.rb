require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe TimePredictor do
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
    let(:ordered_splits) { [split1, split2, split3, split4, split5, split6] }

    it 'initializes with an effort, a sub_split, ordered_splits, and an EffortSegmentCalcs object in an args hash' do
      effort = FactoryGirl.build_stubbed(:effort)
      sub_split = split3.sub_splits.first
      split_times = split_times_101
      calcs = EffortSegmentCalcs.new(split_times: split_times)
      expect { TimePredictor.new(effort: effort,
                                 sub_split: sub_split,
                                 ordered_splits: ordered_splits,
                                 effort_segment_calcs: calcs,
                                 valid_split_times: split_times_101) }.not_to raise_error
    end
  end

  describe '#predicted_time' do
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

    it 'predicts the next expected time from start for an unfinished effort' do
      effort = FactoryGirl.build_stubbed(:effort)
      split_times = [split_times_101, split_times_102, split_times_103, split_times_104,
                     split_times_105, split_times_106, split_times_107, split_times_108,
                     split_times_109, split_times_110, split_times_111, split_times_112].flatten
      sub_split = split4.sub_splits.first
      calcs = EffortSegmentCalcs.new(split_times: split_times)
      predictor = TimePredictor.new(effort: effort,
                                    sub_split: sub_split,
                                    ordered_splits: ordered_splits,
                                    effort_segment_calcs: calcs,
                                    valid_split_times: split_times_112)
      expect(predictor.predicted_time).to be_within(100).of(4500)
    end

    it 'predicts expected time from start for later sub_splits in an unfinished effort' do
      effort = FactoryGirl.build_stubbed(:effort)
      split_times = [split_times_101, split_times_102, split_times_103, split_times_104,
                     split_times_105, split_times_106, split_times_107, split_times_108,
                     split_times_109, split_times_110, split_times_111, split_times_112].flatten
      sub_split = split5.sub_splits.first
      calcs = EffortSegmentCalcs.new(split_times: split_times)
      predictor = TimePredictor.new(effort: effort,
                                    sub_split: sub_split,
                                    ordered_splits: ordered_splits,
                                    effort_segment_calcs: calcs,
                                    valid_split_times: split_times_112)
      expect(predictor.predicted_time).to be_within(100).of(5900)
    end

    it 'predicts expected time from start for the finish sub_split in an unfinished effort' do
      effort = FactoryGirl.build_stubbed(:effort)
      split_times = [split_times_101, split_times_102, split_times_103, split_times_104,
                     split_times_105, split_times_106, split_times_107, split_times_108,
                     split_times_109, split_times_110, split_times_111, split_times_112].flatten
      sub_split = split6.sub_splits.first
      calcs = EffortSegmentCalcs.new(split_times: split_times)
      predictor = TimePredictor.new(effort: effort,
                                    sub_split: sub_split,
                                    ordered_splits: ordered_splits,
                                    effort_segment_calcs: calcs,
                                    valid_split_times: split_times_112)
      expect(predictor.predicted_time).to be_within(100).of(7300)
    end
  end
end