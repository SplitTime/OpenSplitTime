require 'rails_helper'

RSpec.describe DataImport::Csv::TransformSplitsStrategy do
  subject { DataImport::Csv::TransformSplitsStrategy.new(parsed_structs, options) }

  let(:course) { build_stubbed(:course, id: 10)}
  let(:event) { build_stubbed(:event, id: 1, course: course) }
  let(:options) { {event: event} }
  let(:proto_records) { subject.transform }
  let(:parsed_structs) { [
      OpenStruct.new(name: 'Start', distance: 0, kind: 0, sub_split_bitmap: 1),
      OpenStruct.new(name: 'Aid 1', distance: 5, kind: 2, sub_split_bitmap: 65 ),
      OpenStruct.new(name: 'Finish', distance: 10, kind: 1, sub_split_bitmap: 1)
  ] }

  describe '#transform' do
    context 'when event is present and data is all valid' do
      let(:first_proto_record) { proto_records.first }
      let(:second_proto_record) { proto_records.second }
      let(:third_proto_record) { proto_records.third }

      it 'returns the same number of ProtoRecords as it is given OpenStructs' do
        expect(proto_records.size).to eq(3)
        expect(proto_records.all? { |row| row.is_a?(ProtoRecord) }).to eq(true)
      end

      it 'returns rows with effort headers transformed to match the database' do
        expect(first_proto_record.to_h.keys.sort)
            .to eq(%i(base_name course_id distance_from_start kind sub_split_bitmap))
      end

      it 'assigns event.course.id to :course_id' do
        expect(proto_records.map { |pr| pr[:course_id] }).to eq([event.course.id] * parsed_structs.size)
      end

      it 'converts [:distance] from preferred units to meters' do
        expect(proto_records.map { |pr| pr[:distance_from_start] }).to eq([0, 8047, 16093])
      end
    end

    context 'when an event is not provided' do
      let(:options) { {} }

      it 'returns nil and adds an error' do
        expect(proto_records).to be_nil
        expect(subject.errors.size).to eq(1)
        expect(subject.errors.first[:title]).to match(/Event is missing/)
      end
    end
  end
end
