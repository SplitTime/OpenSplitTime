# frozen_string_literal: true

require 'rails_helper'
include BitkeyDefinitions

RSpec.describe ProcessImportedRawTimesJob do
  subject { described_class.new }
  let(:perform_process) { subject.perform(event_group, raw_times) }

  let(:course) { courses(:hardrock_cw) }
  let(:ordered_splits) { course.ordered_splits }
  let(:event_group) { event.event_group }
  let(:event) { events(:hardrock_2016) }
  let(:time_zone) { ActiveSupport::TimeZone[event.home_time_zone] }
  let(:absolute_time_in) { time_zone.parse('2016-07-15 17:00:00') }
  let(:absolute_time_out) { time_zone.parse('2016-07-15 17:20:00') }
  let(:effort) { efforts(:hardrock_2016_start_only) }
  let(:bib_number) { effort.bib_number.to_s }
  let(:split_name) { ordered_splits.second.base_name }
  let(:source) { 'ost-remote-1234' }

  let(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: bib_number, split_name: split_name, sub_split_kind: 'in',
                            absolute_time: absolute_time_in, with_pacer: 'true', stopped_here: 'false', source: source) }
  let(:raw_time_2) { create(:raw_time, event_group: event_group, bib_number: bib_number, split_name: split_name, sub_split_kind: 'out',
                            absolute_time: absolute_time_out, with_pacer: 'true', stopped_here: 'true', source: source) }
  let(:raw_times) { [raw_time_1] }

  describe '#perform' do
    context 'when there is an existing split_time at the time point' do
      let!(:split_time) { create(:split_time, effort: effort, split: existing_split, bitkey: existing_bitkey, absolute_time_local: existing_time_in, pacer: false, stopped_here: true) }
      let(:existing_split) { ordered_splits.second }
      let(:existing_bitkey) { in_bitkey }
      let(:raw_time) { raw_times.first }

      shared_examples 'matches the raw time' do
        it 'does not create a new split time' do
          expect { perform_process }.not_to change { SplitTime.count }
        end

        it 'matches the raw time with the existing split time' do
          perform_process
          raw_time.reload
          expect(raw_time.split_time_id).to eq(split_time.id)
        end

        it 'sets stop and pacer flags to the new values' do
          expect(split_time.pacer).to eq(false)
          expect(split_time.stopped_here).to eq(true)

          perform_process
          split_time.reload

          expect(split_time.pacer).to eq(true)
          expect(split_time.stopped_here).to eq(false)
        end
      end

      context 'when the existing absolute time is identical to the raw time' do
        let(:existing_time_in) { absolute_time_in }

        include_examples 'matches the raw time'
      end

      context 'when the existing absolute time is close to the raw time' do
        let(:existing_time_in) { absolute_time_in + 5.seconds }

        include_examples 'matches the raw time'
      end

      context 'when the existing absolute time is not close to the raw time' do
        let(:existing_time_in) { absolute_time_in + 5.minutes }
        it 'does not create a new split time' do
          expect { perform_process }.not_to change { SplitTime.count }
        end

        it 'does not match the raw time with the existing split time' do
          perform_process
          raw_time.reload
          expect(raw_time.split_time_id).to be_nil
        end

        it 'does not set stop and pacer flags to the new values' do
          expect(split_time.pacer).to eq(false)
          expect(split_time.stopped_here).to eq(true)

          perform_process
          split_time.reload

          expect(split_time.pacer).to eq(false)
          expect(split_time.stopped_here).to eq(true)
        end
      end
    end

    context 'when there is no split time at the time point' do
      let(:existing_time_in) { absolute_time_in }
      let(:existing_split) { ordered_splits.second }
      let(:existing_bitkey) { out_bitkey }
      let(:raw_time) { raw_times.first }

      it 'creates a new split time' do
        expect { perform_process }.to change { SplitTime.count }.by(1)
      end

      it 'matches the raw time to the new split time' do
        perform_process
        new_split_time = SplitTime.last
        raw_time.reload
        expect(raw_time.split_time_id).to eq(new_split_time.id)
      end
    end

    context 'when multiple raw times are imported' do
      let(:raw_times) { [raw_time_1, raw_time_2] }
      let!(:split_time_1) { create(:split_time, effort: effort, split: existing_split_1, bitkey: existing_bitkey_1,
                                   absolute_time_local: existing_time_in, pacer: false, stopped_here: true) }
      let!(:split_time_2) { create(:split_time, effort: effort, split: existing_split_2, bitkey: existing_bitkey_2,
                                   absolute_time_local: existing_time_out, pacer: false, stopped_here: false) }
      let(:split_times) { [split_time_1, split_time_2] }

      let(:existing_split_1) { ordered_splits.second }
      let(:existing_split_2) { ordered_splits.second }
      let(:existing_bitkey_1) { in_bitkey }
      let(:existing_bitkey_2) { out_bitkey }
      let(:existing_time_in) { absolute_time_in }
      let(:existing_time_out) { absolute_time_out }

      shared_examples 'matches both raw times' do
        it 'does not create a new split time' do
          expect { perform_process }.not_to change { SplitTime.count }
        end

        it 'matches the raw times with the existing split times' do
          perform_process
          raw_times.each(&:reload)
          expect(raw_times.map(&:split_time_id)).to match_array([split_time_1.id, split_time_2.id])
        end

        it 'sets stops to the new values' do
          expect(split_time_1.stopped_here).to eq(true)
          expect(split_time_2.stopped_here).to eq(false)

          perform_process
          split_times.each(&:reload)

          expect(split_time_1.stopped_here).to eq(false)
          expect(split_time_2.stopped_here).to eq(true)
        end
      end

      context 'when exact matches for both are present' do
        include_examples 'matches both raw times'
      end

      context 'when both times are within tolerance' do
        let(:existing_time_in) { absolute_time_in + 5.seconds }
        let(:existing_time_out) { absolute_time_out + 5.seconds }

        include_examples 'matches both raw times'
      end

      context 'when only one time point is taken' do
        let(:existing_split_1) { ordered_splits.third }

        it 'creates one new split time' do
          expect { perform_process }.to change { SplitTime.count }.by(1)
        end

        it 'matches the other split time' do
          perform_process
          raw_times.each(&:reload)
          new_split_time = SplitTime.last
          expect(raw_times.map(&:split_time_id)).to match_array([new_split_time.id, split_time_2.id])
        end
      end
    end

    context 'when push notifications are permitted and raw_times do not create new split_times' do
      let(:bib_number) { '*' } # Invalid bib numbers never automatically create split_times
      let(:raw_times) { [raw_time_1, raw_time_2] }

      before { event_group.update(available_live: true, concealed: false) }

      it 'sends a push notification that includes the count of available raw times' do
        expect(event.permit_notifications?).to be(true)
        allow(Pusher).to receive(:trigger)
        perform_process
        expected_args = ["raw-times-available.event_group.#{event_group.id}", 'update', {unconsidered: 2, unmatched: 2}]
        expect(Pusher).to have_received(:trigger).with(*expected_args)
      end
    end

    context 'when event_group.permit_notifications? is true' do
      before { event_group.update(available_live: true, concealed: false) }
      let!(:person) { effort.person }
      let(:raw_times) { [raw_time_1, raw_time_2] }

      it 'creates new split_times matching the raw_times' do
        expect { perform_process }.to change { SplitTime.count }.by(2)
        split_times = SplitTime.last(2)
        raw_times.each(&:reload)

        expect(split_times.map(&:absolute_time_local)).to match_array([absolute_time_in, absolute_time_out])
        expect(split_times.map(&:bitkey)).to match_array([in_bitkey, out_bitkey])

        expect(raw_times.map(&:split_time_id)).to match_array(split_times.map(&:id))
      end

      it 'sends a message to NotifyProgressJob with relevant person and split_time data' do
        allow(NotifyProgressJob).to receive(:perform_later)

        perform_process
        split_times = SplitTime.last(2)
        split_time_ids = split_times.map(&:id)
        effort_id = split_times.first.effort_id

        expect(NotifyProgressJob).to have_received(:perform_later).with(effort_id, array_including(split_time_ids))
      end

      it 'sends messages to Interactors::SetEffortStatus with the efforts associated with the modified split_times' do
        allow(Interactors::SetEffortStatus).to receive(:perform).and_return(Interactors::Response.new([], '', {}))
        perform_process

        expect(Interactors::SetEffortStatus).to have_received(:perform).at_least(2).times
      end
    end
  end
end
