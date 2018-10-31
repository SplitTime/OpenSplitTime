# frozen_string_literal: true

require 'rails_helper'
include BitkeyDefinitions

RSpec.describe Interactors::UpdateEffortsStop do
  subject { Interactors::UpdateEffortsStop.new(efforts, stop_status: stop_status) }
  let(:stop_status) { nil }

  let(:split_times_1) { [split_time_1, split_time_2, split_time_3] }
  let(:split_times_2) { [split_time_4, split_time_5, split_time_6] }

  let(:effort_1) { create(:effort, event: event) }
  let(:effort_2) { create(:effort, event: event) }
  let(:event) { create(:event, course: course) }
  let(:course) { create(:course) }
  let(:split_1) { create(:split, :start, course: course) }
  let(:split_2) { create(:split, course: course) }
  let(:split_3) { create(:split, course: course) }
  let(:split_4) { create(:split, :finish, course: course) }

  describe '#initialize' do
    context 'when efforts is provided' do
      let!(:efforts) { [effort_1, effort_2] }

      it 'initializes without error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when an empty array is provided' do
      let!(:efforts) { [] }

      it 'initializes with an effort' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when no efforts are provided' do
      let!(:efforts) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(/efforts argument was not provided/)
      end
    end
  end

  describe '#perform!' do
    context 'when stops need to be added' do
      let!(:split_time_1) { create(:split_time, effort: effort_1, lap: 1, split: split_1, bitkey: in_bitkey, absolute_time: start_time + 0, stopped_here: false) }
      let!(:split_time_2) { create(:split_time, effort: effort_1, lap: 1, split: split_2, bitkey: in_bitkey, absolute_time: start_time + 10000, stopped_here: false) }
      let!(:split_time_3) { create(:split_time, effort: effort_1, lap: 1, split: split_2, bitkey: out_bitkey, absolute_time: start_time + 11000, stopped_here: false) }
      let!(:split_time_4) { create(:split_time, effort: effort_2, lap: 1, split: split_1, bitkey: in_bitkey, absolute_time: start_time + 0, stopped_here: false) }
      let!(:split_time_5) { create(:split_time, effort: effort_2, lap: 1, split: split_2, bitkey: in_bitkey, absolute_time: start_time + 10000, stopped_here: true) }
      let!(:split_time_6) { create(:split_time, effort: effort_2, lap: 1, split: split_2, bitkey: out_bitkey, absolute_time: start_time + 11000, stopped_here: false) }
      let!(:efforts) { Effort.where(id: [effort_1.id, effort_2.id]).includes(split_times: :split) }

      it 'changes the stopped_here flag for split_times of all efforts and returns changed split_times in its response' do
        response = subject.perform!
        changed_split_times = [split_time_3, split_time_5, split_time_6]
        expect(response.resources).to match_array(changed_split_times)
        expect(SplitTime.where(stopped_here: true)).to match_array([split_time_3, split_time_6])
      end
    end

    context 'when no stops need to be added' do
      let!(:split_time_1) { create(:split_time, effort: effort_1, lap: 1, split: split_1, bitkey: in_bitkey, absolute_time: start_time + 0, stopped_here: false) }
      let!(:split_time_2) { create(:split_time, effort: effort_1, lap: 1, split: split_2, bitkey: in_bitkey, absolute_time: start_time + 10000, stopped_here: false) }
      let!(:split_time_3) { create(:split_time, effort: effort_1, lap: 1, split: split_2, bitkey: out_bitkey, absolute_time: start_time + 11000, stopped_here: true) }
      let!(:split_time_4) { create(:split_time, effort: effort_2, lap: 1, split: split_1, bitkey: in_bitkey, absolute_time: start_time + 0, stopped_here: false) }
      let!(:split_time_5) { create(:split_time, effort: effort_2, lap: 1, split: split_2, bitkey: in_bitkey, absolute_time: start_time + 10000, stopped_here: false) }
      let!(:split_time_6) { create(:split_time, effort: effort_2, lap: 1, split: split_2, bitkey: out_bitkey, absolute_time: start_time + 11000, stopped_here: true) }
      let!(:efforts) { Effort.where(id: [effort_1.id, effort_2.id]).includes(split_times: :split) }

      it 'does not change any split_times and returns an empty array in its response' do
        response = subject.perform!
        changed_split_times = []
        expect(response.resources).to match_array(changed_split_times)
        expect(SplitTime.where(stopped_here: true)).to match_array([split_time_3, split_time_6])
      end
    end

    context 'when no split_times exist for an effort' do
      let!(:split_time_1) { create(:split_time, effort: effort_1, lap: 1, split: split_1, bitkey: in_bitkey, absolute_time: start_time + 0, stopped_here: false) }
      let!(:split_time_2) { create(:split_time, effort: effort_1, lap: 1, split: split_2, bitkey: in_bitkey, absolute_time: start_time + 10000, stopped_here: false) }
      let!(:split_time_3) { create(:split_time, effort: effort_1, lap: 1, split: split_2, bitkey: out_bitkey, absolute_time: start_time + 11000, stopped_here: false) }
      let!(:efforts) { Effort.where(id: [effort_1.id, effort_2.id]).includes(split_times: :split) }

      it 'works as expected' do
        response = subject.perform!
        changed_split_times = [split_time_3]
        expect(response.resources).to match_array(changed_split_times)
        expect(SplitTime.where(stopped_here: true)).to match_array([split_time_3])
      end
    end

    context 'when a single effort is provided without an Array' do
      let!(:split_time_1) { create(:split_time, effort: effort_1, lap: 1, split: split_1, bitkey: in_bitkey, absolute_time: start_time + 0, stopped_here: false) }
      let!(:split_time_2) { create(:split_time, effort: effort_1, lap: 1, split: split_2, bitkey: in_bitkey, absolute_time: start_time + 10000, stopped_here: false) }
      let!(:split_time_3) { create(:split_time, effort: effort_1, lap: 1, split: split_2, bitkey: out_bitkey, absolute_time: start_time + 11000, stopped_here: false) }
      let!(:efforts) { Effort.where(id: [effort_1.id]).includes(split_times: :split).first }

      it 'works as expected' do
        response = subject.perform!
        changed_split_times = [split_time_3]
        expect(response.resources).to match_array(changed_split_times)
        expect(SplitTime.where(stopped_here: true)).to match_array([split_time_3])
      end
    end

    context 'when stops need to be removed' do
      let!(:split_time_1) { create(:split_time, effort: effort_1, lap: 1, split: split_1, bitkey: in_bitkey, absolute_time: start_time + 0, stopped_here: false) }
      let!(:split_time_2) { create(:split_time, effort: effort_1, lap: 1, split: split_2, bitkey: in_bitkey, absolute_time: start_time + 10000, stopped_here: false) }
      let!(:split_time_3) { create(:split_time, effort: effort_1, lap: 1, split: split_2, bitkey: out_bitkey, absolute_time: start_time + 11000, stopped_here: true) }
      let!(:split_time_4) { create(:split_time, effort: effort_2, lap: 1, split: split_1, bitkey: in_bitkey, absolute_time: start_time + 0, stopped_here: false) }
      let!(:split_time_5) { create(:split_time, effort: effort_2, lap: 1, split: split_2, bitkey: in_bitkey, absolute_time: start_time + 10000, stopped_here: true) }
      let!(:split_time_6) { create(:split_time, effort: effort_2, lap: 1, split: split_2, bitkey: out_bitkey, absolute_time: start_time + 11000, stopped_here: false) }
      let!(:efforts) { Effort.where(id: [effort_1.id, effort_2.id]).includes(split_times: :split) }
      let(:stop_status) { false }

      it 'changes the stopped_here flag for split_times of all efforts to false and returns changed split_times in its response' do
        response = subject.perform!
        changed_split_times = [split_time_3, split_time_5]
        expect(response.resources).to match_array(changed_split_times)
        expect(SplitTime.where(stopped_here: true)).to be_empty
      end
    end

    context 'when no stops need to be removed' do
      let!(:split_time_1) { create(:split_time, effort: effort_1, lap: 1, split: split_1, bitkey: in_bitkey, absolute_time: start_time + 0, stopped_here: false) }
      let!(:split_time_2) { create(:split_time, effort: effort_1, lap: 1, split: split_2, bitkey: in_bitkey, absolute_time: start_time + 10000, stopped_here: false) }
      let!(:split_time_3) { create(:split_time, effort: effort_1, lap: 1, split: split_2, bitkey: out_bitkey, absolute_time: start_time + 11000, stopped_here: false) }
      let!(:split_time_4) { create(:split_time, effort: effort_2, lap: 1, split: split_1, bitkey: in_bitkey, absolute_time: start_time + 0, stopped_here: false) }
      let!(:split_time_5) { create(:split_time, effort: effort_2, lap: 1, split: split_2, bitkey: in_bitkey, absolute_time: start_time + 10000, stopped_here: false) }
      let!(:split_time_6) { create(:split_time, effort: effort_2, lap: 1, split: split_2, bitkey: out_bitkey, absolute_time: start_time + 11000, stopped_here: false) }
      let!(:efforts) { Effort.where(id: [effort_1.id, effort_2.id]).includes(split_times: :split) }
      let(:stop_status) { false }

      it 'makes no changes and returns an empty array in its response' do
        response = subject.perform!
        changed_split_times = []
        expect(response.resources).to match_array(changed_split_times)
        expect(SplitTime.where(stopped_here: true)).to be_empty
      end
    end
  end
end
