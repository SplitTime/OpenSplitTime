require 'rails_helper'

RSpec.describe ETL::Loaders::UpsertStrategy do
  subject { ETL::Loaders::UpsertStrategy.new(proto_records, options) }

  let(:course) { create(:course, id: 10) }
  let(:event) { create(:event, id: 1, course: course) }
  let(:options) { {parent: course, event: event, unique_key: [:course_id, :distance_from_start], current_user_id: 111} }
  let(:valid_proto_records) do
    [ProtoRecord.new({record_type: :split, kind: 0, sub_split_bitmap: 1, base_name: 'Start', distance_from_start: 0, course_id: 10}),
     ProtoRecord.new({record_type: :split, kind: 2, sub_split_bitmap: 65, base_name: 'Aid 1', distance_from_start: 5000, course_id: 10}),
     ProtoRecord.new({record_type: :split, kind: 1, sub_split_bitmap: 1, base_name: 'Finish', distance_from_start: 7000, course_id: 10})]
  end
  let(:invalid_proto_records) do
    [ProtoRecord.new({record_type: :split, kind: 1, sub_split_bitmap: 1, base_name: 'Start', distance_from_start: 0, course_id: 10}),
     ProtoRecord.new({record_type: :split, kind: 2, sub_split_bitmap: 65, base_name: 'Aid 1', distance_from_start: -100, course_id: 10})]
  end

  describe '#load_records' do
    context 'when data is valid and no matching records exist' do
      let(:proto_records) { valid_proto_records }

      it 'creates records and saves them to the database' do
        expect { subject.load_records }.to change { Split.count }.by(3)
      end
    end

    context 'when data is valid and one or more matching records exist' do
      let(:proto_records) { valid_proto_records }
      let!(:split) { create(:split, course_id: course.id, distance_from_start: 5000, base_name: 'Old Name') }

      it 'creates non-matching records and updates matching records' do
        expect { subject.load_records }.to change { Split.count }.by(2)
        subject_splits = Split.last(3)
        expect(subject_splits.map(&:base_name)).to match_array(['Start', 'Aid 1', 'Finish'])
      end
    end

    context 'when any proto_record is invalid' do
      let!(:split) { create(:split, course_id: course.id, distance_from_start: 5000, base_name: 'Old Name') }
      let(:proto_records) { valid_proto_records + invalid_proto_records }

      it 'creates no new records and makes invalid records available in the invalid_records array' do
        expect { subject.load_records }.to change { Split.count }.by(0)
        subject_split = Split.last
        expect(subject_split.base_name).to eq('Old Name')
        expect(subject.invalid_records.size).to eq(2)
        expect(subject.invalid_records.map(&:distance_from_start)).to match_array([0, -100])
      end
    end

    context 'when proto_records are efforts for an event with scheduled start offset' do
      let(:event) { create(:event, event_group: event_group, scheduled_start_time_local: event_start_time) }
      let(:event_group) { create(:event_group, home_time_zone: 'Mountain Time (US & Canada)')}
      let(:event_start_time) { '2019-09-14 07:45:00' }
      let(:options) { {parent: event, event: event, unique_key: [:first_name, :last_name], current_user_id: 111} }
      let(:proto_records) do
        [ProtoRecord.new({record_type: :effort, first_name: 'Millie', last_name: 'Canyon', gender: 'female',
                          scheduled_start_offset: offset, event_id: event.id})]
      end
      let(:offset) { 900 }

      it 'sets scheduled start time correctly' do
        expect { subject.load_records }.to change { Effort.count }.by(1)
        effort = Effort.last
        expect(effort.scheduled_start_time).to eq(event.scheduled_start_time + offset)
      end
    end
  end
end
