# frozen_string_literal: true

require 'rails_helper'
include BitkeyDefinitions

RSpec.describe Interactors::UpdateEffortsStop do
  subject { Interactors::UpdateEffortsStop.new(subject_efforts, stop_status: stop_status) }
  let(:subject_efforts) { [effort_1, effort_2] }
  let(:stop_status) { nil }

  describe '#initialize' do
    context 'when an efforts array is provided' do
      let(:effort_1) { efforts(:hardrock_2016_progress_sherman) }
      let(:effort_2) { efforts(:hardrock_2016_start_only) }

      it 'initializes without error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when an empty array is provided' do
      let(:subject_efforts) { [] }

      it 'initializes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when no efforts are provided' do
      let(:subject_efforts) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(/efforts argument was not provided/)
      end
    end
  end

  describe '#perform!' do
    let(:split_time_1) { effort_1.ordered_split_times.last }
    let(:split_time_2) { effort_2.ordered_split_times.last }

    context 'when stops need to be added' do
      let(:effort_1) { efforts(:hardrock_2016_progress_sherman) }
      let(:effort_2) { efforts(:hardrock_2016_start_only) }

      it 'changes the stopped_here flag for split_times of all efforts and returns changed split_times in its response' do
        response = subject.perform!
        expect(response.resources).to match_array([split_time_1, split_time_2])
        expect(SplitTime.where(effort: [effort_1, effort_2], stopped_here: true)).to match_array([split_time_1, split_time_2])
      end
    end

    context 'when no stops need to be added' do
      let(:effort_1) { efforts(:hardrock_2014_finished_first) }
      let(:effort_2) { efforts(:hardrock_2014_drop_ouray) }

      it 'does not change any split_times and returns an empty array in its response' do
        response = subject.perform!
        expect(response.resources).to match_array([])
        expect(SplitTime.where(effort: [effort_1, effort_2], stopped_here: true)).to match_array([split_time_1, split_time_2])
      end
    end

    context 'when no split_times exist for an effort' do
      let(:effort_1) { efforts(:hardrock_2014_not_started) }
      let(:effort_2) { efforts(:hardrock_2016_progress_sherman) }

      it 'works as expected' do
        response = subject.perform!
        expect(response.resources).to match_array([split_time_2])
        expect(SplitTime.where(effort: [effort_1, effort_2], stopped_here: true)).to match_array([split_time_2])
      end
    end

    context 'when a single effort is provided without an Array' do
      let(:effort) { efforts(:hardrock_2016_progress_sherman) }
      let(:subject_efforts) { effort }
      let(:split_times) { [effort.ordered_split_times.last] }

      it 'works as expected' do
        response = subject.perform!
        expect(response.resources).to match_array(split_times)
        expect(SplitTime.where(effort: effort, stopped_here: true)).to match_array(split_times)
      end
    end

    context 'when stops need to be removed' do
      let(:effort_1) { efforts(:hardrock_2014_drop_ouray) }
      let(:effort_2) { efforts(:hardrock_2016_progress_sherman) }
      let(:split_time_1) { effort_1.ordered_split_times.last }
      let(:split_time_2) { effort_2.ordered_split_times.last(2).first }
      let(:stop_status) { false }
      before { split_time_2.update(stopped_here: true) }

      it 'changes the stopped_here flag for split_times of all efforts to false and returns changed split_times in its response' do
        response = subject.perform!
        expect(response.resources).to match_array([split_time_1, split_time_2])
        expect(SplitTime.where(effort: [effort_1, effort_2], stopped_here: true)).to be_empty
      end
    end

    context 'when no stops need to be removed' do
      let(:effort_1) { efforts(:hardrock_2016_start_only) }
      let(:effort_2) { efforts(:hardrock_2016_progress_sherman) }
      let(:stop_status) { false }

      it 'makes no changes and returns an empty array in its response' do
        response = subject.perform!
        expect(response.resources).to match_array([])
        expect(SplitTime.where(effort: [effort_1, effort_2], stopped_here: true)).to be_empty
      end
    end
  end
end
