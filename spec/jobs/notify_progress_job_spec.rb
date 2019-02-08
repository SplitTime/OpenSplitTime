# frozen_string_literal: true

require 'rails_helper'
include BitkeyDefinitions

RSpec.describe NotifyProgressJob do
  subject { NotifyProgressJob.new }
  let(:perform_notification) { subject.perform(effort_id, split_time_ids) }

  let(:effort_id) { effort.id }
  let(:event) { events(:rufa_2017_24h) }
  let(:effort) { efforts(:rufa_2017_24h_progress_lap6) }
  let(:splits) { event.splits }

  describe '#perform' do
    let(:split_time_ids) { notification_split_times.map(&:id) }
    let(:successful_response) { OpenStruct.new(successful?: true, resources: {}) }
    let(:unsuccessful_response) { OpenStruct.new(successful?: false, resources: {}) }
    let(:notification_split_times) { effort.ordered_split_times.last(2) }
    let(:split_time_total_distance) { notification_split_times.last.total_distance }

    context 'when arguments are valid and no farther notifications exist' do
      it 'sends a message to ProgressNotifier' do
        expect(ProgressNotifier).to receive(:publish).and_return(successful_response)
        perform_notification
      end

      it 'creates notifications' do
        expect { perform_notification }.to change { Notification.count }.by(1)
        notification = Notification.last
        expect(notification.effort_id).to eq(effort.id)
        expect(notification.distance).to eq(notification_split_times.last.total_distance)
        expect(notification.bitkey).to eq(notification_split_times.last.bitkey)
        expect(notification.topic_resource_key).to eq(effort.topic_resource_key)
        expect(notification.subject).to eq('Update for Progress Lap6 at RUFA 2017 24H from OpenSplitTime')
      end
    end

    context 'when arguments are valid but a farther notification exists' do
      before do
        create(:notification, kind: :progress, effort: effort, distance: split_time_total_distance + 1000, bitkey: out_bitkey)
      end

      it 'does not sends a message to ProgressNotifier' do
        expect(ProgressNotifier).not_to receive(:publish)
        perform_notification
      end

      it 'does not create notifications' do
        expect { perform_notification }.not_to change { Notification.count }
      end
    end

    context 'when arguments are valid but a notification having identical distance and bitkey exists' do
      before do
        create(:notification, kind: :progress, effort: effort, distance: split_time_total_distance, bitkey: out_bitkey)
      end

      it 'does not sends a message to ProgressNotifier' do
        expect(ProgressNotifier).not_to receive(:publish)
        perform_notification
      end

      it 'does not create notifications' do
        expect { perform_notification }.not_to change { Notification.count }
      end
    end

    context 'when arguments are valid but a notification having identical distance and an earlier bitkey exists' do
      before do
        create(:notification, kind: :progress, effort: effort, distance: split_time_total_distance, bitkey: in_bitkey)
      end

      it 'sends a message to ProgressNotifier' do
        expect(ProgressNotifier).to receive(:publish).and_return(successful_response)
        perform_notification
      end

      it 'creates notifications' do
        expect { perform_notification }.to change { Notification.count }.by(1)
        notification = Notification.last
        expect(notification.effort_id).to eq(effort.id)
        expect(notification.distance).to eq(notification_split_times.last.total_distance)
        expect(notification.bitkey).to eq(notification_split_times.last.bitkey)
      end
    end
  end
end
