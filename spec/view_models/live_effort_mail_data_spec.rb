require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe LiveEffortMailData do
  let(:split_times_101) { FactoryGirl.build_stubbed_list(:split_times_in_out, 5, effort_id: 101) }
  let(:split_ids) { split_times_101.map(&:split_id).uniq }
  let(:split1) { FactoryGirl.build_stubbed(:start_split, id: split_ids[0], course_id: 10, distance_from_start: 0) }
  let(:split2) { FactoryGirl.build_stubbed(:split, id: split_ids[1], course_id: 10, distance_from_start: 1000) }
  let(:split3) { FactoryGirl.build_stubbed(:split, id: split_ids[2], course_id: 10, distance_from_start: 2000) }
  let(:split4) { FactoryGirl.build_stubbed(:split, id: split_ids[3], course_id: 10, distance_from_start: 3000) }
  let(:split5) { FactoryGirl.build_stubbed(:split, id: split_ids[4], course_id: 10, distance_from_start: 4000) }
  let(:split6) { FactoryGirl.build_stubbed(:finish_split, id: split_ids[5], course_id: 10, distance_from_start: 5000) }

  describe '#initialize' do
    it 'initializes with a participant and split_times in an args hash' do
      participant = FactoryGirl.build_stubbed(:participant)
      split_times = split_times_101
      expect { LiveEffortMailData.new(participant: participant, split_times: split_times) }.not_to raise_error
    end

    it 'raises an ArgumentError if no participant or participant_id is given' do
      split_times = split_times_101
      expect { LiveEffortMailData.new(split_times: split_times) }.to raise_error(/must include one of participant or participant_id/)
    end

    it 'raises an ArgumentError if any parameter other than participant, participant_id, split_times, or split_times_ids are given' do
      participant = FactoryGirl.build_stubbed(:participant)
      split_times = split_times_101
      expect { LiveEffortMailData.new(participant: participant, split_times: split_times, random_param: 123) }
          .to raise_error(/may not include random_param/)
    end
  end

  describe '#effort_data' do
    before do
      FactoryGirl.reload
    end

    it 'returns a hash containing effort and split_time data' do
      participant = FactoryGirl.build_stubbed(:participant)
      effort = FactoryGirl.build_stubbed(:effort, id: 101, first_name: 'Joe', last_name: 'Doe', dropped_split_id: 303)
      event = FactoryGirl.build_stubbed(:event, id: 202, name: 'Testrock 100')
      allow(effort).to receive(:event).and_return(event)
      in_split_time = split_times_101[3]
      out_split_time = split_times_101[4]
      split_times = [in_split_time, out_split_time]
      allow(in_split_time).to receive(:effort).and_return(effort)
      allow(in_split_time).to receive(:split).and_return(split3)
      allow(out_split_time).to receive(:effort).and_return(effort)
      allow(out_split_time).to receive(:split).and_return(split3)
      split_times_data = [{split_id: 103,
                           split_name: 'Split 1 In',
                           day_and_time: 'Friday, July 1, 2016  6:33AM',
                           pacer: nil},
                          {split_id: 103,
                           split_name: 'Split 1 Out',
                           day_and_time: 'Friday, July 1, 2016  6:35AM',
                           pacer: nil}]
      mail_data = LiveEffortMailData.new(participant: participant, split_times: split_times)
      expected = {full_name: 'Joe Doe',
                  event_name: 'Testrock 100',
                  dropped_split_id: 303,
                  split_times_data: split_times_data,
                  effort_id: 101,
                  event_id: 202}
      expect(mail_data.effort_data).to eq(expected)
    end
  end
end