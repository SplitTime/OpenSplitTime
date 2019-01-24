# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ETL::Loaders::InsertStrategy do
  subject { ETL::Loaders::InsertStrategy.new(proto_records, options) }
  let!(:event) { create(:event_with_standard_splits, in_sub_splits_only: true, splits_count: 7, start_time_local: '2017-12-25 06:00:00') }
  let(:start_time) { event.start_time }
  let(:splits) { event.ordered_splits }
  let(:split_ids) { splits.map(&:id) }

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
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[2], sub_split_bitkey: 1, absolute_time: start_time + 14398),
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
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[5], sub_split_bitkey: 1, absolute_time: nil),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[6], sub_split_bitkey: 1, absolute_time: start_time + 5000)])
  ] }

  let(:proto_with_military_times) { [
      ProtoRecord.new(record_type: :effort, age: '40', gender: 'male', bib_number: '500',
                      first_name: 'Johtest', last_name: 'Apptest', event_id: event.id,
                      children: [ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[0], sub_split_bitkey: 1, military_time: '06:00:00'),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[1], sub_split_bitkey: 1, military_time: '07:20:00'),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[2], sub_split_bitkey: 1, military_time: '08:40:00'),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[3], sub_split_bitkey: 1, military_time: '10:00:00'),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[4], sub_split_bitkey: 1, military_time: '11:20:00'),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[5], sub_split_bitkey: 1, military_time: '12:40:00'),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[6], sub_split_bitkey: 1, military_time: '14:00:00')])
  ] }

  let(:all_proto_records) { valid_proto_records + invalid_proto_record }
  let(:options) { {event: event, current_user_id: 111} }

  describe '#load_records' do
    context 'when all provided records are valid and none previously exists' do
      let(:proto_records) { valid_proto_records }

      it 'assigns attributes and creates new records of the parent class' do
        efforts = Effort.all
        expect(efforts.size).to eq(0)
        subject.load_records
        expect(efforts.size).to eq(3)
        expect(efforts.map(&:first_name)).to match_array(%w(Jatest Castest Mictest))
        expect(efforts.map(&:bib_number)).to match_array([5, 661, 633])
        expect(efforts.map(&:gender)).to match_array(%w(male female female))
        expect(efforts.map(&:event_id)).to all eq(event.id)
      end

      it 'assigns attributes and saves new child records' do
        split_times = SplitTime.all
        expect(split_times.size).to eq(0)
        subject.load_records
        expect(split_times.size).to eq(10)
        expect(split_times.map(&:split_id)).to match_array(split_ids.cycle.first(split_times.size))
        expected_absolute_times = [0, 2581, 6308, 9463, 13571, 16655, 17736, 0, 4916, 14398].map { |e| start_time + e }
        expect(split_times.map(&:absolute_time)).to match_array(expected_absolute_times)
        expect(split_times.map(&:effort_id)).to match_array([Effort.first.id] * 7 + [Effort.second.id] * 3)
      end

      it 'returns saved parent records in the saved_records array and assigns a current user id to created_by' do
        subject.load_records
        expect(subject.saved_records.size).to eq(3)
        expect(subject.saved_records.map(&:created_by)).to all eq(options[:current_user_id])
      end
    end

    context 'when valid records have children with military_time attributes' do
      let(:proto_records) { proto_with_military_times }
      before { FactoryBot.reload }

      it 'assigns attributes and creates new records of the parent class' do
        efforts = Effort.all
        expect(efforts.size).to eq(0)
        subject.load_records
        expect(efforts.size).to eq(1)
        expect(efforts.first.first_name).to eq('Johtest')
        expect(efforts.first.bib_number).to eq(500)
        expect(efforts.first.gender).to eq('male')
        expect(efforts.first.event_id).to eq(event.id)
      end

      it 'assigns attributes and saves new child records' do
        split_times = SplitTime.all
        expect(split_times.size).to eq(0)
        subject.load_records
        expect(split_times.size).to eq(7)
        expect(split_times.map(&:split_id)).to match_array(split_ids.cycle.first(split_times.size))
        expect(split_times.map(&:time_from_start)).to match_array([0, 80.minutes, 160.minutes, 240.minutes, 320.minutes, 400.minutes, 480.minutes])
        expect(split_times.map(&:effort_id)).to all eq(Effort.first.id)
      end
    end

    context 'when one or more records exists' do
      let(:proto_records) { valid_proto_records }
      let(:first_child) { valid_proto_records.first.children.first }
      let(:second_child) { valid_proto_records.first.children.second }

      before do
        existing_effort = create(:effort, event: event, bib_number: valid_proto_records.first[:bib_number])
        create(:split_time, effort: existing_effort, lap: first_child[:lap], split_id: first_child[:split_id],
               bitkey: first_child[:sub_split_bitkey], time_from_start: 0)
        create(:split_time, effort: existing_effort, lap: second_child[:lap], split_id: second_child[:split_id],
               bitkey: second_child[:sub_split_bitkey], time_from_start: 1000)
      end

      it 'rolls back the transaction' do
        expect(Effort.all.size).to eq(1)
        expect(SplitTime.all.size).to eq(2)
        subject.load_records
        expect(Effort.all.size).to eq(1)
        expect(SplitTime.all.size).to eq(2)
      end

      it 'returns the problematic records in an invalid_records array' do
        subject.load_records
        expect(subject.invalid_records.size).to eq(1)
        subject_record = subject.invalid_records.first
        expect(subject_record.bib_number).to eq(valid_proto_records.first[:bib_number].to_i)
        expect(subject_record.errors.full_messages).to include(/Bib number [\d] already exists/)
      end
    end

    context 'when any provided record is invalid' do
      let(:proto_records) { all_proto_records }

      it 'does not create any records of the parent or child class' do
        subject.load_records
        expect(Effort.all.size).to eq(0)
        expect(SplitTime.all.size).to eq(0)
      end

      it 'includes invalid records in the invalid_records and errors attributes' do
        subject.load_records
        expect(subject.invalid_records.size).to eq(1)
        subject_record = subject.invalid_records.first
        expect(subject_record.first_name).to eq('N.n.')
      end
    end

    context 'when a parent record is valid but at least one child record is invalid' do
      let(:proto_records) { proto_with_invalid_child }

      it 'does not create any records of the parent or child class' do
        subject.load_records
        expect(Effort.all.size).to eq(0)
        expect(SplitTime.all.size).to eq(0)
      end

      it 'places the parent record into invalid_records' do
        subject.load_records
        expect(subject.invalid_records.size).to eq(1)
        subject_record = subject.invalid_records.first
        expect(subject_record.first_name).to eq('Johtest')
      end

      it 'includes the child record with the parent record specifying problems with the child record' do
        subject.load_records
        subject_record = subject.invalid_records.first
        expect(subject_record.split_times.map { |st| st.errors.full_messages })
            .to include(["Absolute time can't be blank"])
      end
    end
  end
end
