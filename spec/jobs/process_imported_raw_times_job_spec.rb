# frozen_string_literal: true

require 'rails_helper'
include BitkeyDefinitions

RSpec.describe ProcessImportedRawTimesJob do
  subject { ProcessImportedRawTimesJob.new }
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

  let(:raw_times) { [raw_time_1, raw_time_2] }

  describe '#perform' do
    shared_examples 'processes raw times as expected' do
      context 'when there is a matching split_time in the database' do
        let(:split) { ordered_splits.second }
        let!(:split_time) { create(:split_time, effort: effort, split: split, bitkey: in_bitkey, absolute_time_local: absolute_time_in, pacer: true, stopped_here: false) }

        it 'saves the raw_times to the database, matches the duplicate raw_time with the existing split_time, and creates a new split_time' do
          expect { perform_process }.to change { SplitTime.count }.by(1)
          new_split_time = SplitTime.last
          raw_times.each(&:reload)

          expect(raw_times.map(&:split_time_id)).to match_array([split_time.id, new_split_time.id])
        end
      end

      context 'when there is a non-duplicate split_time in the database' do
        let(:effort) { create(:effort, bib_number: 333, event: event) }
        let(:split) { ordered_splits.first }
        let(:absolute_time_local) { time_zone.parse(absolute_time_in) }
        let!(:split_time) { create(:split_time, effort: effort, split: split, bitkey: in_bitkey, absolute_time_local: absolute_time_in + 2.minutes, pacer: true, stopped_here: false) }

        it 'does not match any raw_time with the existing split_time' do
          expect { perform_process }.to change { SplitTime.count }.by(0)
          raw_times.each(&:reload)

          expect(raw_times.map(&:split_time_id)).to all be_nil
        end
      end

      context 'when push notifications are permitted and raw_times do not create new split_times' do
        let(:bib_number) { '*' } # Invalid bib numbers never automatically create split_times

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

        it 'creates new split_times matching the raw_times' do
          expect { perform_process }.to change { SplitTime.count }.by(2)
          split_times = SplitTime.last(2)
          raw_times.each(&:reload)

          expect(split_times.map(&:absolute_time_local)).to match_array([absolute_time_in, absolute_time_out])
          expect(split_times.map(&:bitkey)).to match_array([in_bitkey, out_bitkey])

          expect(raw_times.map(&:split_time_id)).to match_array(split_times.map(&:id))
        end

        it 'sends a message to NotifyProgressJob with relevant person and split_time data' do
          allow(NotifyProgressJob).to receive(:perform_later) do |_, split_time_ids|
            split_time_ids.sort!
          end

          perform_process
          split_times = SplitTime.last(2)
          split_time_ids = split_times.map(&:id)
          effort_id = split_times.first.effort_id

          expect(NotifyProgressJob).to have_received(:perform_later).with(effort_id, split_time_ids.sort)
        end

        it 'sends messages to Interactors::SetEffortStatus with the efforts associated with the modified split_times' do
          allow(Interactors::SetEffortStatus).to receive(:perform).and_return(Interactors::Response.new([], '', {}))
          perform_process

          expect(Interactors::SetEffortStatus).to have_received(:perform).at_least(2).times
        end
      end
    end

    context 'when raw times have absolute times but no entered times' do
      let(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: bib_number, split_name: split_name, sub_split_kind: 'in',
                                absolute_time: absolute_time_in, entered_time: nil, with_pacer: 'true', stopped_here: 'false', source: source) }
      let(:raw_time_2) { create(:raw_time, event_group: event_group, bib_number: bib_number, split_name: split_name, sub_split_kind: 'out',
                                absolute_time: absolute_time_out, entered_time: nil, with_pacer: 'true', stopped_here: 'true', source: source) }

      include_examples 'processes raw times as expected'
    end

    context 'when raw times have entered times but no absolute times' do
      let(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: bib_number, split_name: split_name, sub_split_kind: 'in',
                                absolute_time: nil, entered_time: absolute_time_in, with_pacer: 'true', stopped_here: 'false', source: source) }
      let(:raw_time_2) { create(:raw_time, event_group: event_group, bib_number: bib_number, split_name: split_name, sub_split_kind: 'out',
                                absolute_time: nil, entered_time: absolute_time_out, with_pacer: 'true', stopped_here: 'true', source: source) }

      include_examples 'processes raw times as expected'
    end
  end
end
