require 'rails_helper'

RSpec.describe DataImport::InsertLoadStrategy do
  let(:event) { create(:event_with_standard_splits, in_sub_splits_only: true, splits_count: 7) }
  let(:splits) { event.ordered_splits }
  let(:split_ids) { splits.ids }

  let(:valid_proto_records) { [
      ProtoRecord.new(record_type: :effort, age: '39', gender: 'male', bib_number: '5',
                      first_name: 'Jatest', last_name: 'Schtest', event_id: event.id, concealed: true,
                      children: [ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[0], sub_split_bitkey: 1, time_from_start: 0.0),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[1], sub_split_bitkey: 1, time_from_start: 2581.36),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[2], sub_split_bitkey: 1, time_from_start: 6308.86),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[3], sub_split_bitkey: 1, time_from_start: 9463.56),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[4], sub_split_bitkey: 1, time_from_start: 13571.37),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[5], sub_split_bitkey: 1, time_from_start: 16655.3),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[6], sub_split_bitkey: 1, time_from_start: 17736.45)]),
      ProtoRecord.new(record_type: :effort, age: '31', gender: 'female', bib_number: '661',
                      first_name: 'Castest', last_name: 'Pertest', event_id: event.id, concealed: true,
                      children: [ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[0], sub_split_bitkey: 1, time_from_start: 0.0),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[1], sub_split_bitkey: 1, time_from_start: 4916.63),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[2], sub_split_bitkey: 1, time_from_start: 14398.48),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[3], sub_split_bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[4], sub_split_bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[5], sub_split_bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[6], sub_split_bitkey: 1, time_from_start: nil)]),
      ProtoRecord.new(record_type: :effort, age: '35', gender: 'female', bib_number: '633',
                      first_name: 'Mictest', last_name: 'Hintest', event_id: event.id, concealed: true,
                      children: [ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[0], sub_split_bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[1], sub_split_bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[2], sub_split_bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[3], sub_split_bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[4], sub_split_bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[5], sub_split_bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[6], sub_split_bitkey: 1, time_from_start: nil)])
  ] }

  let(:invalid_proto_record) { [
      ProtoRecord.new(record_type: :effort, age: '0', gender: '', bib_number: '62',
                      first_name: 'N.n.', last_name: '62', event_id: event.id, concealed: true,
                      children: [ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[0], sub_split_bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[1], sub_split_bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[2], sub_split_bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[3], sub_split_bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[4], sub_split_bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[5], sub_split_bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[6], sub_split_bitkey: 1, time_from_start: nil)])
  ] }

  let(:proto_with_invalid_child) { [
      ProtoRecord.new(record_type: :effort, age: '40', gender: 'male', bib_number: '500',
                      first_name: 'Johtest', last_name: 'Apptest', event_id: event.id, concealed: true,
                      children: [ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[0], sub_split_bitkey: 1, time_from_start: 0.0),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[1], sub_split_bitkey: 1, time_from_start: 1000.0),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[2], sub_split_bitkey: 1, time_from_start: 2000.0),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[3], sub_split_bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[4], sub_split_bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[5], sub_split_bitkey: 1, time_from_start: -999.0),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[6], sub_split_bitkey: 1, time_from_start: 5000.0)])
  ] }

  let(:all_proto_records) { valid_proto_records + invalid_proto_record }
  let(:options) { {event: event, current_user_id: 111} }

  describe '#load_records' do
    context 'when all provided records are valid and none previously exists' do
      subject { DataImport::InsertLoadStrategy.new(valid_proto_records, options) }

      it 'assigns attributes and creates new records of the parent class' do
        efforts = Effort.all
        expect(efforts.size).to eq(0)
        subject.load_records
        expect(efforts.size).to eq(3)
        expect(efforts.map(&:first_name)).to eq(%w(Jatest Castest Mictest))
        expect(efforts.map(&:bib_number)).to eq([5, 661, 633])
        expect(efforts.map(&:gender)).to eq(%w(male female female))
        expect(efforts.map(&:event_id)).to eq([event.id] * efforts.size)
      end

      it 'assigns attributes and saves new child records' do
        split_times = SplitTime.all
        expect(split_times.size).to eq(0)
        subject.load_records
        expect(split_times.size).to eq(10)
        expect(split_times.map(&:split_id)).to eq(split_ids.cycle.first(split_times.size))
        expect(split_times.map(&:time_from_start)).to eq([0.0, 2581.36, 6308.86, 9463.56, 13571.37, 16655.3, 17736.45, 0.0, 4916.63, 14398.48])
        expect(split_times.map(&:effort_id)).to eq([Effort.first.id] * 7 + [Effort.second.id] * 3)
      end

      it 'returns saved parent records in the saved_records array and assigns a current user id to created_by' do
        subject.load_records
        expect(subject.saved_records.size).to eq(3)
        expect(subject.saved_records.map(&:created_by)).to eq([options[:current_user_id]] * subject.saved_records.size)
      end

      it 'for any child proto_record marked with record_action == :destroy, ignores the record' do
        subject.load_records
        expect(subject.ignored_records.size).to eq(11)
      end
    end

    context 'when one or more records exists' do
      let(:first_child) { valid_proto_records.first.children.first }
      let(:second_child) { valid_proto_records.first.children.second }

      before do
        existing_effort = create(:effort, event: event, bib_number: valid_proto_records.first[:bib_number])
        create(:split_time, effort: existing_effort, lap: first_child[:lap], split_id: first_child[:split_id],
               bitkey: first_child[:sub_split_bitkey], time_from_start: 0)
        create(:split_time, effort: existing_effort, lap: second_child[:lap], split_id: second_child[:split_id],
               bitkey: second_child[:sub_split_bitkey], time_from_start: 1000)
      end

      subject { DataImport::InsertLoadStrategy.new(valid_proto_records, options) }

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
        expect(subject_record.errors.full_messages).to include('Bib number has already been taken')
      end
    end

    context 'when any provided record is invalid' do
      subject { DataImport::InsertLoadStrategy.new(all_proto_records, options) }

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
      subject { DataImport::InsertLoadStrategy.new(proto_with_invalid_child, options) }

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
            .to include(['Time from start must be greater than or equal to 0'])
      end
    end
  end
end
