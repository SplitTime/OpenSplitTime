# frozen_string_literal: true

require 'rails_helper'
include BitkeyDefinitions

RSpec.describe NotifyProgressJob do
  subject { NotifyProgressJob.new }
  let(:perform_notification) { subject.perform(effort_id: effort_id, split_time_ids: split_time_ids) }

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
        expect { perform_notification }.to change { Notification.count }.by(2)
        notifications = Notification.last(2)
        expect(notifications.pluck(:effort_id)).to all eq(effort.id)
        expect(notifications.pluck(:distance)).to match_array(notification_split_times.map(&:total_distance))
        expect(notifications.pluck(:bitkey)).to match_array(notification_split_times.map(&:bitkey))
      end
    end

    context 'when arguments are valid but farther notifications exist' do
      before do
        create(:notification, kind: :progress, effort: effort, distance: split_time_total_distance + 1000, bitkey: out_bitkey)
      end

      it 'does not sends a message to ProgressNotifier' do
        expect(ProgressNotifier).not_to receive(:publish)
        subject.perform(effort_id: effort_id, split_time_ids: split_time_ids)
      end

      it 'does not create notifications' do
        expect { perform_notification }.not_to change { Notification.count }
      end
    end
  end
end
