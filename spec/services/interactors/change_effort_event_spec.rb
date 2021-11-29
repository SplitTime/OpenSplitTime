# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Interactors::ChangeEffortEvent do
  subject { Interactors::ChangeEffortEvent.new(effort: effort, new_event: new_event) }

  describe '#initialization' do
    let(:effort) { efforts(:sum_55k_finished_first) }
    let(:new_event) { events(:sum_100k) }

    it 'initializes when provided with an effort and a new_event' do
      expect { subject }.not_to raise_error
    end

    context 'if no effort is provided' do
      let(:effort) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(/must include effort/)
      end
    end

    context 'if no new_event is provided' do
      let(:new_event) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(/must include new_event/)
      end
    end
  end

  describe '#perform!' do
    context 'when the new event has the same splits as the old' do
      let(:effort) { efforts(:rufa_2017_12h_finished_first) }
      let(:new_event) { events(:rufa_2017_24h) }

      it 'updates the effort event_id to the id of the provided event' do
        expect(effort.event_id).not_to eq(new_event.id)
        response = subject.perform!
        expect(effort.event_id).to eq(new_event.id)
        expect(response).to be_successful
        expect(response.message).to match(/was changed from/)
      end

      it 'does not change the split_id of any effort split_times' do
        subject.perform!
        expect(effort.split_times.map(&:changed?)).to all eq(false)
      end
    end

    context 'when the new event has different splits from the old' do
      let(:effort) { efforts(:sum_55k_progress_rolling) }
      let(:new_event) { events(:sum_100k) }

      it 'updates the effort event_id to the id of the provided event' do
        expect(effort.event_id).not_to eq(new_event.id)
        response = subject.perform!

        expect(response).to be_successful
        expect(response.message).to match(/was changed from/)
        expect(effort.event_id).to eq(new_event.id)
      end

      it 'changes the split_ids of effort split_times to the corresponding split_ids of the new event' do
        time_points = new_event.required_time_points.first(effort.split_times.size)
        expect(effort.ordered_split_times.map(&:time_point)).not_to match_array(time_points)
        subject.perform!
        expect(effort.ordered_split_times.map(&:time_point)).to match_array(time_points)
      end

      it 'raises an error if split names do not coincide' do
        split = new_event.ordered_splits.second
        split.update(base_name: split.base_name + '123')
        new_event.reload
        response = subject.perform!
        expect(response).not_to be_successful
        expect(response.errors.first[:detail][:messages]).to include(/split names do not coincide/)
      end

      it 'raises an error if sub_splits do not coincide' do
        split = new_event.ordered_splits.second
        split.update(sub_split_bitmap: 1)
        new_event.reload
        response = subject.perform!
        expect(response).not_to be_successful
        expect(response.errors.first[:detail][:messages]).to include(/sub splits do not coincide/)
      end

      it 'raises an error if laps are out of range' do
        split_time = effort.ordered_split_times.last
        split_time.update(lap: 2)
        response = subject.perform!
        expect(response).not_to be_successful
        expect(response.errors.first[:detail][:messages]).to include(/laps exceed maximum required/)
      end
    end

    context 'when the effort cannot be moved to the new event' do
      let(:effort) { create(:effort, event: old_event, bib_number: 26) }
      let(:new_event) { events(:hardrock_2015) }
      let(:old_event) { events(:hardrock_2014) }
      let(:existing_effort) { new_event.efforts.find_by(bib_number: 26) }

      it 'returns an error response' do
        response = subject.perform!
        expect(response).not_to be_successful
        expect(response.errors.first[:detail][:messages])
            .to include("Bib number #{effort.bib_number} already exists for #{existing_effort.full_name}")
      end
    end
  end
end
