require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe SplitTimeQuery do
  let(:in_bitkey) { SubSplit::IN_BITKEY }
  let(:out_bitkey) { SubSplit::OUT_BITKEY }
  let(:lap_1) { 1 }

  describe '.typical_segment_time' do
    before do
      FactoryGirl.reload
      course = FactoryGirl.create(:course)
      splits = FactoryGirl.create_list(:splits_hardrock_ccw, 3, course: course)
      event = FactoryGirl.create(:event, course: course)
      event.splits << splits
      efforts = FactoryGirl.create_list(:efforts_hardrock, 4, event: event)
      split_time_simulations = [:split_times_hardrock_45, :split_times_hardrock_43, :split_times_hardrock_41, :split_times_hardrock_38]
      efforts.zip(split_time_simulations).each do |effort, simulation|
        split_times = FactoryGirl.create_list(simulation, 5, effort: effort, data_status: 2)
        effort.split_times << split_times
      end
      expect(Course.all.size).to eq(1)
      expect(Split.all.size).to eq(3)
      expect(Event.all.size).to eq(1)
      expect(Effort.all.size).to eq(4)
      expect(SplitTime.all.size).to eq(20)
    end

    let(:start_split) { Split.find_by(base_name: 'Start') }
    let(:cunningham_split) { Split.find_by(base_name: 'Cunningham') }
    let(:maggie_split) { Split.find_by(base_name: 'Maggie') }
    let(:start) { TimePoint.new(lap_1, start_split.id, in_bitkey)}
    let(:cunningham_in) { TimePoint.new(lap_1, cunningham_split.id, in_bitkey)}
    let(:maggie_in) { TimePoint.new(lap_1, maggie_split.id, in_bitkey)}
    let(:maggie_out) { TimePoint.new(lap_1, maggie_split.id, out_bitkey)}
    let(:start_to_cunningham_in) { Segment.new(begin_point: start, end_point: cunningham_in)}
    let(:in_aid_maggie) { Segment.new(begin_point: maggie_in, end_point: maggie_out)}

    it 'returns average time and count for a course segment' do
      segment = start_to_cunningham_in
      effort_ids = nil
      time, count = SplitTimeQuery.typical_segment_time(segment, effort_ids)
      expect(time).to be_within(100).of(10000)
      expect(count).to eq(4)
    end

    it 'ignores any time if data_status of either the begin or end time is bad or questionable' do
      effort_1 = Effort.first
      effort_2 = Effort.second
      split_time_1 = SplitTime.find_by(split: maggie_split, sub_split_bitkey: in_bitkey, effort: effort_1)
      split_time_2 = SplitTime.find_by(split: maggie_split, sub_split_bitkey: out_bitkey, effort: effort_2)
      split_time_1.bad!
      split_time_2.questionable!
      segment = in_aid_maggie
      effort_ids = nil
      _, count = SplitTimeQuery.typical_segment_time(segment, effort_ids)
      expect(count).to eq(2)
    end

    it 'returns average time and count for an in-aid segment and limits the scope of the query when effort_ids are provided' do
      segment = in_aid_maggie
      effort_ids = Effort.all.ids.first(2)
      time, count = SplitTimeQuery.typical_segment_time(segment, effort_ids)
      expect(time).to be_within(50).of(200)
      expect(count).to eq(2)
    end
  end
end
