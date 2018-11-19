# frozen_string_literal: true

require 'rails_helper'
include BitkeyDefinitions

RSpec.describe NotifyFollowersJob do
  subject { NotifyFollowersJob.new(person_id: person_id, split_time_ids: split_time_ids) }
  let(:person_id) { person.id }
  let(:event) { create(:event_with_standard_splits, splits_count: 3, laps_required: 0) }
  let(:effort) { create(:effort, event: event) }
  let(:splits) { event.splits }

  describe '#perform' do
    let(:person) { create(:person) }
    let(:split_time_ids) { notification_split_times.map(&:id) }
    let(:successful_response) { OpenStruct.new(successful?: true) }
    let(:unsuccessful_response) { OpenStruct.new(successful?: false) }
    let(:split_time_1) { create(:split_time, effort: effort, lap: 1, split: splits.second, bitkey: in_bitkey) }
    let(:split_time_2) { create(:split_time, effort: effort, lap: 1, split: splits.second, bitkey: out_bitkey) }
    let(:notification_split_times) { [split_time_1, split_time_2] }
    let(:split_time_total_distance) { split_time_2.total_distance }

    context 'when arguments are valid and no farther notifications exist' do
      it 'sends a message to FollowerNotifier' do
        expect(FollowerNotifier).to receive(:publish).and_return(successful_response)
        subject.perform(person_id: person_id, split_time_ids: split_time_ids)
      end

      it 'creates notifications' do
        expect(Notification.count).to eq(0)
        subject.perform(person_id: person_id, split_time_ids: split_time_ids)
        expect(Notification.count).to eq(2)
        expect(Notification.all.pluck(:effort_id)).to all eq(effort.id)
        expect(Notification.all.pluck(:distance)).to match_array([split_time_1.total_distance, split_time_2.total_distance])
        expect(Notification.all.pluck(:bitkey)).to match_array([in_bitkey, out_bitkey])
      end
    end

    context 'when arguments are valid but farther notifications exist' do
      before do
        create(:notification, effort: effort, distance: split_time_total_distance + 1000, bitkey: out_bitkey)
      end

      it 'does not sends a message to FollowerNotifier' do
        expect(FollowerNotifier).not_to receive(:publish)
        subject.perform(person_id: person_id, split_time_ids: split_time_ids)
      end

      it 'does not creates notifications' do
        expect(Notification.count).to eq(1)
        subject.perform(person_id: person_id, split_time_ids: split_time_ids)
        expect(Notification.count).to eq(1)
      end
    end
  end

  describe '#farther_notification_exists?' do
    let(:person) { build_stubbed(:person) }
    let(:split_time_ids) { [] }
    let(:split_time) { create(:split_time, effort: effort, lap: lap, split: split, bitkey: bitkey) }
    let(:lap) { 1 }
    let(:split) { splits.second }
    let(:bitkey) { in_bitkey }
    let(:split_time_total_distance) { split_time.total_distance }

    context 'when no notifications exist' do
      it 'returns false' do
        expect(subject.send(:farther_notification_exists?, split_time)).to eq(false)
      end
    end

    context 'when notifications exist only for earlier splits' do
      before do
        create(:notification, effort: effort, distance: split_time_total_distance - 1000, bitkey: in_bitkey)
        create(:notification, effort: effort, distance: split_time_total_distance - 1000, bitkey: out_bitkey)
      end

      it 'returns false' do
        expect(subject.send(:farther_notification_exists?, split_time)).to eq(false)
      end
    end

    context 'when notifications exist only for later splits' do
      before do
        create(:notification, effort: effort, distance: split_time_total_distance + 1000, bitkey: in_bitkey)
        create(:notification, effort: effort, distance: split_time_total_distance + 1000, bitkey: out_bitkey)
      end

      it 'returns true' do
        expect(subject.send(:farther_notification_exists?, split_time)).to eq(true)
      end
    end

    context 'when notifications exist for both earlier and later splits' do
      before do
        create(:notification, effort: effort, distance: split_time_total_distance - 1000, bitkey: in_bitkey)
        create(:notification, effort: effort, distance: split_time_total_distance + 1000, bitkey: in_bitkey)
      end

      it 'returns true' do
        expect(subject.send(:farther_notification_exists?, split_time)).to eq(true)
      end
    end

    context 'when notifications exist for the same distance but an earlier bitkey' do
      let(:bitkey) { out_bitkey }

      before do
        create(:notification, effort: effort, distance: split_time_total_distance, bitkey: in_bitkey)
      end

      it 'returns false' do
        expect(subject.send(:farther_notification_exists?, split_time)).to eq(false)
      end
    end

    context 'when notifications exist for the same distance and same bitkey' do
      let(:bitkey) { in_bitkey }

      before do
        create(:notification, effort: effort, distance: split_time_total_distance, bitkey: in_bitkey)
      end

      it 'returns false' do
        expect(subject.send(:farther_notification_exists?, split_time)).to eq(false)
      end
    end

    context 'when notifications exist for the same distance but a later bitkey' do
      let(:bitkey) { in_bitkey }

      before do
        create(:notification, effort: effort, distance: split_time_total_distance, bitkey: out_bitkey)
      end

      it 'returns true' do
        expect(subject.send(:farther_notification_exists?, split_time)).to eq(true)
      end
    end
  end
end
