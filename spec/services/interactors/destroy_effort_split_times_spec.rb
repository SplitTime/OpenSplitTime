# frozen_string_literal: true

require 'rails_helper'
include BitkeyDefinitions

RSpec.describe Interactors::DestroyEffortSplitTimes do
  subject { Interactors::DestroyEffortSplitTimes.new(effort, split_time_ids) }
  let!(:split_time_1) { create(:split_time, effort: effort, lap: 1, split: split_1, bitkey: in_bitkey, time_from_start: 0, stopped_here: false) }
  let!(:split_time_2) { create(:split_time, effort: effort, lap: 1, split: split_2, bitkey: in_bitkey, time_from_start: 10000, stopped_here: false) }
  let!(:split_time_3) { create(:split_time, effort: effort, lap: 1, split: split_2, bitkey: out_bitkey, time_from_start: 11000, stopped_here: false) }
  let!(:split_time_4) { create(:split_time, effort: effort, lap: 1, split: split_3, bitkey: in_bitkey, time_from_start: 20000, stopped_here: false) }
  let!(:split_time_5) { create(:split_time, effort: effort, lap: 1, split: split_3, bitkey: out_bitkey, time_from_start: 21000, stopped_here: true) }
  let(:split_time_ids) { split_times.map { |st| st.id.to_s } }

  let(:effort) { create(:effort, event: event) }
  let(:event) { create(:event, course: course) }
  let(:course) { create(:course) }
  let(:split_1) { create(:split, :start, course: course) }
  let(:split_2) { create(:split, course: course) }
  let(:split_3) { create(:split, course: course) }
  let(:split_4) { create(:split, :finish, course: course) }

  before { effort.reload }

  describe '#initialize' do
    context 'when effort and split_time_ids arguments are provided' do
      let(:split_times) { [split_time_4, split_time_5] }

      it 'initializes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when no effort is provided' do
      subject { Interactors::DestroyEffortSplitTimes.new(nil, split_time_ids) }
      let(:split_times) { [split_time_4, split_time_5] }

      it 'raises an error' do
        expect { subject }.to raise_error(/effort argument was not provided/)
      end
    end

    context 'when no split_time_ids argument is provided' do
      subject { Interactors::DestroyEffortSplitTimes.new(effort, nil) }

      it 'raises an error' do
        expect { subject }.to raise_error(/split_time_ids argument was not provided/)
      end
    end

    context 'when split_time_ids are not included in effort.split_time ids' do
      let(:split_time_ids) { %w[0, 1] }

      it 'raises an error' do
        expect { subject }.to raise_error(/split_time ids 0, 1 do not correspond to effort/)
      end
    end
  end

  describe '#perform!' do
    context 'when split_time_ids are provided and include a stopped split_time' do
      let(:split_times) { [split_time_4, split_time_5] }

      it 'destroys the provided split_times, resets the stop, and returns changed and destroyed split_times' do
        expect(effort.split_times.size).to eq(5)
        response = subject.perform!
        effort.reload
        expect(effort.split_times.size).to eq(3)
        split_time_3.reload
        expect(split_time_3.stopped_here).to eq(true)
        expect(response.resources).to match_array([split_time_3, split_time_4, split_time_5])
      end
    end

    context 'when split_time_ids are provided and do not include a stopped split_time' do
      let(:split_times) { [split_time_3, split_time_4] }

      it 'destroys the provided split_times and returns destroyed split_times' do
        expect(effort.split_times.size).to eq(5)
        response = subject.perform!
        effort.reload
        expect(effort.split_times.size).to eq(3)
        split_time_5.reload
        expect(split_time_5.stopped_here).to eq(true)
        expect(response.resources).to match_array([split_time_3, split_time_4])
      end
    end

    context 'when no split_time_ids are provided' do
      let(:split_times) { [] }

      it 'changes nothing and returns a successful response' do
        expect(effort.split_times.size).to eq(5)
        response = subject.perform!
        effort.reload
        expect(effort.split_times.size).to eq(5)
        expect(response.resources).to match_array([])
      end
    end
  end
end
