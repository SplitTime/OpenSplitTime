require 'rails_helper'

RSpec.describe ETL::Loaders::SplitTimeUpsertStrategy do
  let(:event) { create(:event_with_standard_splits, in_sub_splits_only: true, splits_count: 7) }
  let(:splits) { event.ordered_splits }
  let(:split_ids) { splits.map(&:id) }

  let(:valid_proto_records) { [
      ProtoRecord.new(record_type: :effort, age: '39', gender: 'male', bib_number: '5',
                      first_name: 'Jatest', last_name: 'Schtest', event_id: event.id,
                      children: [ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[0], sub_split_bitkey: 1, time_from_start: 0.0),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[1], sub_split_bitkey: 1, time_from_start: 2581.36),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[2], sub_split_bitkey: 1, time_from_start: 6308.86),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[3], sub_split_bitkey: 1, time_from_start: 9463.56),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[4], sub_split_bitkey: 1, time_from_start: 13571.37),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[5], sub_split_bitkey: 1, time_from_start: 16655.3),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[6], sub_split_bitkey: 1, time_from_start: 17736.45)]),
      ProtoRecord.new(record_type: :effort, age: '31', gender: 'female', bib_number: '661',
                      first_name: 'Castest', last_name: 'Pertest', event_id: event.id,
                      children: [ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[0], sub_split_bitkey: 1, time_from_start: 0.0),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[1], sub_split_bitkey: 1, time_from_start: 4916.63),
                                 ProtoRecord.new(record_type: :split_time, lap: 1, split_id: split_ids[2], sub_split_bitkey: 1, time_from_start: 14398.48, stopped_here: true),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[3], sub_split_bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[4], sub_split_bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[5], sub_split_bitkey: 1, time_from_start: nil),
                                 ProtoRecord.new(record_type: :split_time, record_action: :destroy, lap: 1, split_id: split_ids[6], sub_split_bitkey: 1, time_from_start: nil)]),
      ProtoRecord.new(record_type: :effort, age: '35', gender: 'female', bib_number: '633',
                      first_name: 'Mictest', last_name: 'Hintest', event_id: event.id,
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
                      first_name: 'N.n.', last_name: '62', event_id: event.id,
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
                      first_name: 'Johtest', last_name: 'Apptest', event_id: event.id,
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
    context 'when no matching parent records exist' do
      subject { ETL::Loaders::SplitTimeUpsertStrategy.new(valid_proto_records, options) }

      it 'does not import any records and places all parent records into ignored_records' do
        subject.load_records
        expect(Effort.all.size).to eq(0)
        expect(SplitTime.all.size).to eq(0)
        expect(subject.ignored_records.size).to eq(3)
      end
    end

    context 'when matching parent records exist for proto_records' do
      subject { ETL::Loaders::SplitTimeUpsertStrategy.new(valid_proto_records, options) }
      let!(:effort_1) { create(:effort, event: event, bib_number: valid_proto_records.first[:bib_number]) }
      let!(:effort_3) { create(:effort, event: event, bib_number: valid_proto_records.third[:bib_number]) }

      it 'assigns attributes and saves new child records' do
        split_times = SplitTime.all
        expect(split_times.size).to eq(0)
        subject.load_records

        expect(split_times.size).to eq(7)
        expect(split_times.map(&:split_id).sort).to eq(split_ids.cycle.first(split_times.size).sort)
        expect(split_times.map(&:time_from_start)).to eq([0.0, 2581.36, 6308.86, 9463.56, 13571.37, 16655.3, 17736.45])
        expect(split_times.map(&:effort_id)).to all eq(effort_1.id)
        expect(split_times.map(&:created_by)).to all eq(options[:current_user_id])
      end

      it 'returns saved parent records in the saved_records array' do
        subject.load_records
        expect(subject.saved_records.size).to eq(2)
        expect(subject.saved_records.map(&:id)).to match_array(Effort.all.ids)
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
                                   bitkey: first_child[:sub_split_bitkey], time_from_start: 0) }
      let!(:split_time_2) { create(:split_time, effort: existing_effort, lap: second_child[:lap], split_id: second_child[:split_id],
                                   bitkey: second_child[:sub_split_bitkey], time_from_start: 1000) }

      subject { ETL::Loaders::SplitTimeUpsertStrategy.new(valid_proto_records, options) }

      it 'finds existing records based on a unique key and updates provided fields' do
        expect(Effort.count).to eq(1)
        expect(SplitTime.count).to eq(2)
        expect(existing_effort.split_times.pluck(:time_from_start)).to match_array([0.0, 1000])

        subject.load_records

        expect(subject.saved_records.size).to eq(1)
        expect(Effort.count).to eq(1)
        expect(SplitTime.count).to eq(7)
        expect(existing_effort.split_times.pluck(:time_from_start)).to match_array([0.0, 2581.36, 6308.86, 9463.56, 13571.37, 16655.3, 17736.45])
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
                                   bitkey: first_child[:sub_split_bitkey], time_from_start: 0) }
      let!(:split_time_2) { create(:split_time, effort: existing_effort, lap: second_child[:lap], split_id: second_child[:split_id],
                                   bitkey: second_child[:sub_split_bitkey], time_from_start: 1000) }
      let!(:split_time_3) { create(:split_time, effort: existing_effort, lap: third_child[:lap], split_id: third_child[:split_id],
                                   bitkey: third_child[:sub_split_bitkey], time_from_start: 2000) }
      let!(:split_time_4) { create(:split_time, effort: existing_effort, lap: fourth_child[:lap], split_id: fourth_child[:split_id],
                                   bitkey: fourth_child[:sub_split_bitkey], time_from_start: 3000) }
      let!(:split_time_5) { create(:split_time, effort: existing_effort, lap: fifth_child[:lap], split_id: fifth_child[:split_id],
                                   bitkey: fifth_child[:sub_split_bitkey], time_from_start: 4000) }

      subject { ETL::Loaders::SplitTimeUpsertStrategy.new(valid_proto_records, options) }

      it 'finds existing records based on a unique key and deletes times where blanks exist' do
        expect(Effort.all.size).to eq(1)
        expect(SplitTime.all.size).to eq(5)
        expect(existing_effort.split_times.pluck(:time_from_start)).to eq([0.0, 1000.0, 2000.0, 3000.0, 4000.0])
        subject.load_records
        expect(Effort.all.size).to eq(1)
        expect(SplitTime.all.size).to eq(3)
        expect(existing_effort.split_times.pluck(:time_from_start)).to eq([0.0, 4916.63, 14398.48])
      end
    end

    context 'when update results in more than one split_time having a stopped_here flag set' do
      let(:first_child) { valid_proto_records.first.children.first }
      let(:second_child) { valid_proto_records.first.children.second }
      let!(:existing_effort) { create(:effort, event: event, bib_number: valid_proto_records.second[:bib_number]) }
      let!(:split_time_1) { create(:split_time, effort: existing_effort, lap: first_child[:lap], split_id: first_child[:split_id],
                                   bitkey: first_child[:sub_split_bitkey], time_from_start: 0) }
      let!(:split_time_2) { create(:split_time, effort: existing_effort, lap: second_child[:lap], split_id: second_child[:split_id],
                                   bitkey: second_child[:sub_split_bitkey], time_from_start: 1000, stopped_here: true) }

      subject { ETL::Loaders::SplitTimeUpsertStrategy.new(valid_proto_records, options) }

      it 'sets the stop on the last split_time' do
        expect(Effort.all.size).to eq(1)
        expect(SplitTime.all.size).to eq(2)
        expect(existing_effort.split_times.pluck(:time_from_start)).to match_array([0.0, 1000])

        subject.load_records

        expect(subject.saved_records.size).to eq(1)
        expect(Effort.all.size).to eq(1)
        expect(SplitTime.all.size).to eq(3)
        expect(existing_effort.split_times.pluck(:time_from_start)).to match_array([0.0, 4916.63, 14398.48])
        expect(existing_effort.split_times.pluck(:stopped_here)).to match_array([false, false, true])
      end
    end

    context 'when any provided child record is invalid' do
      let(:first_child) { proto_with_invalid_child.first.children.first }
      let(:second_child) { proto_with_invalid_child.first.children.second }
      let!(:existing_effort) { create(:effort, event: event, bib_number: proto_with_invalid_child.first[:bib_number]) }
      let!(:split_time_1) { create(:split_time, effort: existing_effort, lap: first_child[:lap], split_id: first_child[:split_id],
                                   bitkey: first_child[:sub_split_bitkey], time_from_start: 0) }
      let!(:split_time_2) { create(:split_time, effort: existing_effort, lap: second_child[:lap], split_id: second_child[:split_id],
                                   bitkey: second_child[:sub_split_bitkey], time_from_start: 1000) }

      subject { ETL::Loaders::SplitTimeUpsertStrategy.new(proto_with_invalid_child, options) }

      it 'does not create any child records for the related parent record' do
        expect(Effort.all.size).to eq(1)
        expect(SplitTime.all.size).to eq(2)
        subject.load_records
        expect(Effort.all.size).to eq(1)
        expect(SplitTime.all.size).to eq(2)
      end

      it 'includes invalid records in the invalid_records array' do
        subject.load_records
        expect(subject.invalid_records.size).to eq(1)
        expect(subject.invalid_records.first.errors.full_messages).to include('Split times time from start must be greater than or equal to 0')
      end
    end
  end
end
