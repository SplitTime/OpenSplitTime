require 'rails_helper'

RSpec.describe ETL::Loaders::UpsertStrategy do
  subject { ETL::Loaders::UpsertStrategy.new(proto_records, options) }

  let(:course) { create(:course, id: 10) }
  let(:event) { create(:event, id: 1, course: course) }
  let(:options) { {event: event, unique_key: [:course_id, :distance_from_start], current_user_id: 111} }
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
        expect(Split.all.size).to eq(0)
        subject.load_records
        expect(Split.all.size).to eq(3)
      end
    end

    context 'when data is valid and one or more matching records exist' do
      let(:proto_records) { valid_proto_records }
      let!(:split) { create(:split, course_id: course.id, distance_from_start: 5000, base_name: 'Old Name') }

      it 'creates non-matching records and updates matching records' do
        expect(Split.all.size).to eq(1)
        subject.load_records
        expect(Split.all.size).to eq(3)
        expect(Split.all.map(&:base_name)).to match_array(['Start', 'Aid 1', 'Finish'])
      end
    end

    context 'when any proto_record is invalid' do
      let!(:split) { create(:split, course_id: course.id, distance_from_start: 5000, base_name: 'Old Name') }
      let(:proto_records) { valid_proto_records + invalid_proto_records }

      it 'creates no new records and makes invalid records available in the invalid_records array' do
        expect(Split.all.size).to eq(1)
        subject.load_records
        expect(Split.all.size).to eq(1)
        expect(Split.first.base_name).to eq('Old Name')
        expect(subject.invalid_records.size).to eq(2)
        expect(subject.invalid_records.map(&:distance_from_start)).to match_array([0, -100])
      end
    end
  end
end
