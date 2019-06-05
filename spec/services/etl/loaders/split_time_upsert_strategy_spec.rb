# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ETL::Loaders::SplitTimeUpsertStrategy do
  let(:event) { events(:ggd30_50k) }
  let(:start_time) { event.start_time }
  let(:subject_splits) { event.ordered_splits }
  let(:split_ids) { subject_splits.map(&:id) }
  let(:invalid_split_id) { 0 }

  let(:valid_proto_records) { [
      ProtoRecord.new(record_type: :effort, age: '39', gender: 'male', bib_number: '5',
                      first_name: 'Jatest', last_name: 'Schtest', event_id: event.id,
                      children: [ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[0], sub_split_bitkey: 1, absolute_time: start_time + 0),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[1], sub_split_bitkey: 1, absolute_time: start_time + 2581),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[2], sub_split_bitkey: 1, absolute_time: start_time + 6308),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[3], sub_split_bitkey: 1, absolute_time: start_time + 9463),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[4], sub_split_bitkey: 1, absolute_time: start_time + 13571),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[5], sub_split_bitkey: 1, absolute_time: start_time + 16655),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[6], sub_split_bitkey: 1, absolute_time: start_time + 17736)]),
      ProtoRecord.new(record_type: :effort, age: '31', gender: 'female', bib_number: '661',
                      first_name: 'Castest', last_name: 'Pertest', event_id: event.id,
                      children: [ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[0], sub_split_bitkey: 1, absolute_time: start_time + 0),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[1], sub_split_bitkey: 1, absolute_time: start_time + 4916),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[2], sub_split_bitkey: 1, absolute_time: start_time + 14398, stopped_here: true),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[3], sub_split_bitkey: 1, absolute_time: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[4], sub_split_bitkey: 1, absolute_time: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[5], sub_split_bitkey: 1, absolute_time: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[6], sub_split_bitkey: 1, absolute_time: nil)]),
      ProtoRecord.new(record_type: :effort, age: '35', gender: 'female', bib_number: '633',
                      first_name: 'Mictest', last_name: 'Hintest', event_id: event.id,
                      children: [ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[0], sub_split_bitkey: 1, absolute_time: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[1], sub_split_bitkey: 1, absolute_time: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[2], sub_split_bitkey: 1, absolute_time: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[3], sub_split_bitkey: 1, absolute_time: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[4], sub_split_bitkey: 1, absolute_time: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[5], sub_split_bitkey: 1, absolute_time: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[6], sub_split_bitkey: 1, absolute_time: nil)])
  ] }

  let(:invalid_proto_record) { [
      ProtoRecord.new(record_type: :effort, age: '0', gender: '', bib_number: '62',
                      first_name: 'N.n.', last_name: '62', event_id: event.id,
                      children: [ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[0], sub_split_bitkey: 1, absolute_time: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[1], sub_split_bitkey: 1, absolute_time: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[2], sub_split_bitkey: 1, absolute_time: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[3], sub_split_bitkey: 1, absolute_time: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[4], sub_split_bitkey: 1, absolute_time: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[5], sub_split_bitkey: 1, absolute_time: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[6], sub_split_bitkey: 1, absolute_time: nil)])
  ] }

  let(:proto_with_invalid_child) { [
      ProtoRecord.new(record_type: :effort, age: '40', gender: 'male', bib_number: '500',
                      first_name: 'Johtest', last_name: 'Apptest', event_id: event.id,
                      children: [ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[0], sub_split_bitkey: 1, absolute_time: start_time + 0),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[1], sub_split_bitkey: 1, absolute_time: start_time + 1000),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[2], sub_split_bitkey: 1, absolute_time: start_time + 2000),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[3], sub_split_bitkey: 1, absolute_time: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[4], sub_split_bitkey: 1, absolute_time: nil),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[5], sub_split_bitkey: 1, absolute_time: start_time + 4500),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: invalid_split_id, sub_split_bitkey: 1, absolute_time: start_time + 5000)])
  ] }

  let(:all_proto_records) { valid_proto_records + invalid_proto_record }
  let(:options) { {event: event, current_user_id: 111} }

  let(:saved_efforts) { subject.saved_records.select { |record| record.is_a?(Effort) } }
  let(:saved_split_times) { subject.saved_records.select { |record| record.is_a?(SplitTime) } }

  describe '#load_records' do
    context 'when no matching parent records exist' do
      subject { ETL::Loaders::SplitTimeUpsertStrategy.new(valid_proto_records, options) }

      it 'does not import any records and places all parent records into ignored_records' do
        expect { subject.load_records }.to change { Effort.count }.by(0).and change { SplitTime.count }.by(0)
        expect(subject.ignored_records.size).to eq(3)
      end
    end

    context 'when matching parent records exist for proto_records' do
      subject { ETL::Loaders::SplitTimeUpsertStrategy.new(valid_proto_records, options) }
      let!(:effort_1) { create(:effort, event: event, bib_number: valid_proto_records.first[:bib_number]) }
      let!(:effort_3) { create(:effort, event: event, bib_number: valid_proto_records.third[:bib_number]) }

      it 'assigns attributes, saves new child records, and puts new child records into saved_records' do
        expect { subject.load_records }.to change { Effort.count }.by(0).and change { SplitTime.count }.by(7)
        subject_split_times = SplitTime.last(7)

        expect(subject_split_times.map(&:split_id).sort).to eq(split_ids.cycle.first(subject_split_times.size).sort)
        expect(subject_split_times.map(&:absolute_time)).to eq([0, 2581, 6308, 9463, 13571, 16655, 17736].map { |e| start_time + e })
        expect(subject_split_times.map(&:effort_id)).to all eq(effort_1.id)
        expect(subject_split_times.map(&:created_by)).to all eq(options[:current_user_id])
      end

      it 'returns saved parent records in the saved_records array' do
        subject.load_records
        expect(saved_efforts.size).to eq(2)
        expect(saved_efforts.map(&:id)).to match_array([effort_1.id, effort_3.id])
      end

      it 'returns newly saved child records in the saved_records array' do
        subject.load_records
        expect(saved_split_times.size).to eq(7)
        expect(saved_split_times.map(&:absolute_time)).to eq([0, 2581, 6308, 9463, 13571, 16655, 17736].map { |e| start_time + e })
      end

      it 'returns unsaved parent records in the ignored_records array' do
        subject.load_records
        expect(subject.ignored_records.size).to eq(1)
        expect(subject.ignored_records.map(&:id)).to all be_nil
      end
    end

    context 'when one or more child records exist with times in conflict' do
      let(:first_child) { valid_proto_records.first.children.first }
      let(:second_child) { valid_proto_records.first.children.second }
      let!(:existing_effort) { create(:effort, event: event, bib_number: valid_proto_records.first[:bib_number]) }
      let!(:split_time_1) { create(:split_time, effort: existing_effort, lap: first_child[:lap], split_id: first_child[:split_id],
                                   bitkey: first_child[:sub_split_bitkey], absolute_time: start_time + 0) }
      let!(:split_time_2) { create(:split_time, effort: existing_effort, lap: second_child[:lap], split_id: second_child[:split_id],
                                   bitkey: second_child[:sub_split_bitkey], absolute_time: start_time + 1000) }

      subject { ETL::Loaders::SplitTimeUpsertStrategy.new(valid_proto_records, options) }

      it 'finds existing records based on a unique key and updates provided fields' do
        existing_effort.reload
        expect(existing_effort.split_times.pluck(:absolute_time)).to match_array([0, 1000].map { |e| start_time + e })

        expect { subject.load_records }.to change { Effort.count }.by(0).and change { SplitTime.count }.by(5)

        expect(saved_efforts.size).to eq(1)
        expect(saved_split_times.size).to eq(5)
        expect(existing_effort.split_times.pluck(:absolute_time)).to match_array([0, 2581, 6308, 9463, 13571, 16655, 17736].map { |e| start_time + e })
      end
    end

    context 'when the update contains blanks in the place of one or more existing child records' do
      let(:first_child) { valid_proto_records.first.children.first }
      let(:second_child) { valid_proto_records.first.children.second }
      let(:third_child) { valid_proto_records.second.children.third }
      let(:fourth_child) { valid_proto_records.second.children.fourth }
      let(:fifth_child) { valid_proto_records.second.children.fifth }
      let!(:existing_effort) { create(:effort, event: event, bib_number: valid_proto_records.second[:bib_number]) }
      let!(:split_time_1) { create(:split_time, effort: existing_effort, lap: first_child[:lap], split_id: first_child[:split_id],
                                   bitkey: first_child[:sub_split_bitkey], absolute_time: start_time + 0) }
      let!(:split_time_2) { create(:split_time, effort: existing_effort, lap: second_child[:lap], split_id: second_child[:split_id],
                                   bitkey: second_child[:sub_split_bitkey], absolute_time: start_time + 1000) }
      let!(:split_time_3) { create(:split_time, effort: existing_effort, lap: third_child[:lap], split_id: third_child[:split_id],
                                   bitkey: third_child[:sub_split_bitkey], absolute_time: start_time + 2000) }
      let!(:split_time_4) { create(:split_time, effort: existing_effort, lap: fourth_child[:lap], split_id: fourth_child[:split_id],
                                   bitkey: fourth_child[:sub_split_bitkey], absolute_time: start_time + 3000) }
      let!(:split_time_5) { create(:split_time, effort: existing_effort, lap: fifth_child[:lap], split_id: fifth_child[:split_id],
                                   bitkey: fifth_child[:sub_split_bitkey], absolute_time: start_time + 4000) }

      subject { ETL::Loaders::SplitTimeUpsertStrategy.new(valid_proto_records, options) }

      it 'finds existing records based on a unique key and deletes times where blanks exist' do
        existing_effort.reload
        expect(existing_effort.ordered_split_times.pluck(:absolute_time)).to eq([0, 1000, 2000, 3000, 4000].map { |e| start_time + e })
        expect { subject.load_records }.to change { Effort.count }.by(0).and change { SplitTime.count }.by(-2)
        existing_effort.reload
        expect(existing_effort.ordered_split_times.pluck(:absolute_time)).to eq([0, 4916, 14398].map { |e| start_time + e })
      end
    end

    context 'when update results in more than one split_time having a stopped_here flag set' do
      let(:first_child) { valid_proto_records.first.children.first }
      let(:second_child) { valid_proto_records.first.children.second }
      let!(:existing_effort) { create(:effort, event: event, bib_number: valid_proto_records.second[:bib_number]) }
      let!(:split_time_1) { create(:split_time, effort: existing_effort, lap: first_child[:lap], split_id: first_child[:split_id],
                                   bitkey: first_child[:sub_split_bitkey], absolute_time: start_time + 0) }
      let!(:split_time_2) { create(:split_time, effort: existing_effort, lap: second_child[:lap], split_id: second_child[:split_id],
                                   bitkey: second_child[:sub_split_bitkey], absolute_time: start_time + 1000, stopped_here: true) }

      subject { ETL::Loaders::SplitTimeUpsertStrategy.new(valid_proto_records, options) }

      it 'sets the stop on the last split_time' do
        existing_effort.reload
        expect(existing_effort.split_times.pluck(:absolute_time)).to match_array([0, 1000].map { |e| start_time + e })

        expect { subject.load_records }.to change { Effort.count }.by(0).and change { SplitTime.count }.by(1)

        expect(saved_efforts.size).to eq(1)
        expect(existing_effort.split_times.pluck(:absolute_time)).to match_array([0, 4916, 14398].map { |e| start_time + e })
        expect(existing_effort.split_times.pluck(:stopped_here)).to match_array([false, false, true])
      end
    end

    context 'when any provided child record is invalid' do
      let(:first_child) { proto_with_invalid_child.first.children.first }
      let(:second_child) { proto_with_invalid_child.first.children.second }
      let!(:existing_effort) { create(:effort, event: event, bib_number: proto_with_invalid_child.first[:bib_number]) }
      let!(:split_time_1) { create(:split_time, effort: existing_effort, lap: first_child[:lap], split_id: first_child[:split_id],
                                   bitkey: first_child[:sub_split_bitkey], absolute_time: start_time + 0) }
      let!(:split_time_2) { create(:split_time, effort: existing_effort, lap: second_child[:lap], split_id: second_child[:split_id],
                                   bitkey: second_child[:sub_split_bitkey], absolute_time: start_time + 1000) }

      subject { ETL::Loaders::SplitTimeUpsertStrategy.new(proto_with_invalid_child, options) }

      it 'does not create any child records for the related parent record' do
        expect { subject.load_records }.to change { Effort.count }.by(0).and change { SplitTime.count }.by(0)
      end

      it 'includes invalid records in the invalid_records array' do
        subject.load_records
        expect(subject.invalid_records.size).to eq(1)
        expect(subject.invalid_records.first.errors.full_messages).to include("Split times split can't be blank")
      end
    end
  end
end
