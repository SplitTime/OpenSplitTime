require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe NewLiveEffortData do
  let(:split_times_101) { FactoryGirl.build_stubbed_list(:split_times_in_out, 20, effort_id: 101) }
  let(:split_ids) { split_times_101.map(&:split_id).uniq }
  let(:split1) { FactoryGirl.build_stubbed(:start_split, id: split_ids[0], course_id: 10, distance_from_start: 0) }
  let(:split2) { FactoryGirl.build_stubbed(:split, id: split_ids[1], course_id: 10, distance_from_start: 1000) }
  let(:split3) { FactoryGirl.build_stubbed(:split, id: split_ids[2], course_id: 10, distance_from_start: 2000) }
  let(:split4) { FactoryGirl.build_stubbed(:split, id: split_ids[3], course_id: 10, distance_from_start: 3000) }
  let(:split5) { FactoryGirl.build_stubbed(:split, id: split_ids[4], course_id: 10, distance_from_start: 4000) }
  let(:split6) { FactoryGirl.build_stubbed(:finish_split, id: split_ids[5], course_id: 10, distance_from_start: 5000) }

  describe '#initialize' do
    it 'initializes with an event and params in an args hash' do
      event = FactoryGirl.build_stubbed(:event)
      params = {'splitId' => '2', 'bibNumber' => '124', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      expect { NewLiveEffortData.new(event: event, params: params) }.not_to raise_error
    end

    it 'raises an ArgumentError if no event is given' do
      params = {'splitId' => '2', 'bibNumber' => '124', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      expect { NewLiveEffortData.new(params: params) }.to raise_error(/must include event/)
    end

    it 'raises an ArgumentError if any parameter other than event, params, ordered_splits, or times_container is given' do
      event = FactoryGirl.build_stubbed(:event)
      params = {'splitId' => '2', 'bibNumber' => '124', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      expect { NewLiveEffortData.new(event: event, params: params, random_param: 123) }
          .to raise_error(/may not include random_param/)
    end
  end

  describe '#new_split_times' do
    let(:event) { FactoryGirl.build_stubbed(:event, id: 20) }
    let(:efforts) { FactoryGirl.build_stubbed_list(:effort, 5, event_id: 20) }
    let(:times_container) { SegmentTimesContainer.new(calc_model: :terrain) }

    it 'returns a hash of {in: SplitTime} when the split contains only an in sub_split' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      effort = FactoryGirl.build_stubbed(:effort, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      params = {'splitId' => split_ids[0], 'bibNumber' => '205', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      effort_data = NewLiveEffortData.new(event: event,
                                          params: params,
                                          ordered_splits: ordered_splits,
                                          effort: effort)
      expect(effort_data.new_split_times.size).to eq(1)
      expect(effort_data.new_split_times[:in]).to be_a(SplitTime)
    end

    it 'returns a hash of sub_split kinds and SplitTimes when the split contains multiple sub_splits' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      effort = FactoryGirl.build_stubbed(:effort, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      params = {'splitId' => split_ids[1].to_s, 'bibNumber' => '205', 'timeIn' => '08:30:00', 'timeOut' => '08:50:00', 'id' => '4'}
      effort_data = NewLiveEffortData.new(event: event,
                                          params: params,
                                          ordered_splits: ordered_splits,
                                          effort: effort)
      expect(effort_data.new_split_times.size).to eq(2)
      expect(effort_data.new_split_times[:in]).to be_a(SplitTime)
      expect(effort_data.new_split_times[:out]).to be_a(SplitTime)
    end
  end
end